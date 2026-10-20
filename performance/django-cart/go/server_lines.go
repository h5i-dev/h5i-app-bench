package main

import (
	"context"
	"encoding/json"
	"fmt"
	"github.com/jackc/pgx/v5/pgxpool"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

func serveLines() {
	capLines := envInt("CART_LINES", 32)
	if capLines < 1 || capLines > 2048 {
		panic("CART_LINES")
	}
	rowWidth := 2*capLines + 3
	ctx := context.Background()
	config, e := pgxpool.ParseConfig(os.Getenv("DATABASE_URL"))
	if e != nil {
		panic(e)
	}
	config.MaxConns = 16
	pool, e := pgxpool.NewWithConfig(ctx, config)
	if e != nil {
		panic(e)
	}
	defer pool.Close()
	mode := os.Getenv("MODE")
	limit := envInt("BATCH_MAX", 256)
	if limit < 1 {
		panic("BATCH_MAX")
	}
	delay := time.Duration(envInt("BATCH_WAIT_US", 1000)) * time.Microsecond
	var stats metrics
	queue := make(chan request, 4096)
	if mode != "sql" {
		go func() {
			for first := range queue {
				batch := []request{first}
				deadline := first.arrived.Add(delay)
				for len(batch) < limit {
					select {
					case q := <-queue:
						batch = append(batch, q)
						continue
					default:
					}
					remaining := time.Until(deadline)
					if remaining <= 0 {
						break
					}
					timer := time.NewTimer(remaining)
					select {
					case q := <-queue:
						timer.Stop()
						batch = append(batch, q)
					case <-timer.C:
					}
				}
				start := time.Now()
				ids := make([]int64, len(batch))
				for i, q := range batch {
					ids[i] = q.id
					stats.wait.Add(uint64(start.Sub(q.arrived).Nanoseconds()))
				}
				stats.batches.Add(1)
				stats.sql.Add(1)
				if uint64(len(batch)) > stats.max.Load() {
					stats.max.Store(uint64(len(batch)))
				}
				rows, err := pool.Query(ctx, rawSQL, ids)
				packed := map[int64][]uint64{}
				if err == nil {
					for rows.Next() {
						var id, kind, value int64
						var slot, price, qty *int64
						if err = rows.Scan(&id, &kind, &value, &slot, &price, &qty); err != nil {
							break
						}
						r := packed[id]
						if r == nil {
							r = make([]uint64, rowWidth)
							r[rowWidth-2] = uint64(kind)
							r[rowWidth-1] = uint64(value)
							packed[id] = r
						}
						if slot != nil {
							if *slot < 0 || *slot >= int64(capLines) {
								err = fmt.Errorf("bad slot")
								break
							}
							j := r[0]
							if j >= uint64(capLines) {
								err = fmt.Errorf("too many lines")
								break
							}
							r[0]++
							r[1+j] = uint64(*price)
							r[1+uint64(capLines)+j] = uint64(*qty)
						}
					}
					if err == nil {
						err = rows.Err()
					}
					rows.Close()
				}
				stats.rows.Add(uint64(len(packed)))
				for _, q := range batch {
					a := answer{404, 0}
					if err != nil {
						a.code = 500
					} else if r := packed[q.id]; r != nil {
						a = answer{200, wideTotal(r, capLines)}
						if a.total == invalid {
							a.code = 500
						}
					}
					q.reply <- a
				}
			}
		}()
	}
	mux := http.NewServeMux()
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) { w.Write([]byte("ok")) })
	mux.HandleFunc("/metrics", func(w http.ResponseWriter, r *http.Request) { json.NewEncoder(w).Encode(stats.snapshot()) })
	mux.HandleFunc("/carts/", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "GET" {
			w.WriteHeader(405)
			return
		}
		path := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
		if len(path) != 3 || path[0] != "carts" || path[2] != "total" {
			http.NotFound(w, r)
			return
		}
		id, e := strconv.ParseInt(path[1], 10, 64)
		if e != nil || id < 1 {
			w.WriteHeader(400)
			return
		}
		stats.requests.Add(1)
		a := answer{500, 0}
		if mode == "sql" {
			stats.batches.Add(1)
			stats.sql.Add(1)
			stats.max.Store(1)
			var got, kind, value, subtotal int64
			e := pool.QueryRow(r.Context(), aggregateSQL, id).Scan(&got, &kind, &value, &subtotal)
			if e == nil {
				stats.rows.Add(1)
				a = answer{200, finish(uint64(subtotal), uint64(kind), uint64(value))}
			} else if e.Error() == "no rows in result set" {
				a.code = 404
			}
		} else {
			q := request{id, time.Now(), make(chan answer, 1)}
			select {
			case queue <- q:
				select {
				case a = <-q.reply:
				case <-r.Context().Done():
					return
				}
			default:
				a.code = 503
			}
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(a.code)
		if a.code == 200 {
			json.NewEncoder(w).Encode(map[string]any{"id": id, "total_cents": a.total})
		} else {
			w.Write([]byte("{}"))
		}
	})
	port := envInt("PORT", 8780)
	log.Printf("go mode=%s batch=%d wait=%s", mode, limit, delay)
	log.Fatal(http.ListenAndServe(fmt.Sprintf("127.0.0.1:%d", port), mux))
}

func wideTotal(r []uint64, capLines int) uint64 {
	if len(r) != 2*capLines+3 || r[0] > uint64(capLines) || r[len(r)-2] > 2 || r[len(r)-1] > max {
		return invalid
	}
	var subtotal uint64
	for j := 0; j < int(r[0]); j++ {
		p, q := r[1+j], r[1+capLines+j]
		if p > max || q < 1 || q > 1000 {
			return invalid
		}
		subtotal += p * q
	}
	return finish(subtotal, r[len(r)-2], r[len(r)-1])
}
