// Standalone single-thread baseline. No third-party dependencies.
package main

import (
	"encoding/binary"
	"encoding/csv"
	"fmt"
	"io"
	"os"
	"strconv"
	"time"
)

const width = 67
const max = 99999999
const invalid = ^uint64(0)

func total(r []uint64) uint64 {
	if len(r) != width || r[0] > 32 || r[65] > 2 || r[66] > max {
		return invalid
	}
	var subtotal uint64
	for j := 0; j < int(r[0]); j++ {
		p, q := r[1+j], r[33+j]
		if p > max || q == 0 || q > 1000 {
			return invalid
		}
		subtotal += p * q
	}
	return finish(subtotal, r[65], r[66])
}

func finish(subtotal, kind, value uint64) uint64 {
	scaled := subtotal * 10000
	if kind == 1 {
		v := value
		if v > 10000 {
			v = 10000
		}
		scaled -= subtotal * v
	}
	if kind == 2 {
		v := value * 10000
		if v > scaled {
			v = scaled
		}
		scaled -= v
	}
	return (scaled + 5000) / 10000
}
func calculate(rows []uint64) []uint64 {
	out := make([]uint64, len(rows)/width)
	for i := range out {
		out[i] = total(rows[i*width : (i+1)*width])
	}
	return out
}
func fixture(n, lines int) []uint64 {
	rows := make([]uint64, n*width)
	for i := 0; i < n; i++ {
		r := rows[i*width : (i+1)*width]
		r[0] = uint64(lines)
		for j := 0; j < lines; j++ {
			r[1+j] = uint64((i*7919 + j*104729) % 100000)
			r[33+j] = uint64((i+j)%9 + 1)
		}
		r[65] = uint64(i % 3)
		r[66] = uint64(i % 100000)
		if i%3 == 1 {
			r[66] = []uint64{0, 1, 1250, 3333, 9999, 10000, 15000}[i%7]
		}
	}
	return rows
}
func equal(a, b []uint64) {
	if len(a) != len(b) {
		panic("length mismatch")
	}
	for i := range a {
		if a[i] != b[i] {
			panic("total mismatch")
		}
	}
}

var sink []uint64

func main() {
	if len(os.Args) > 1 && os.Args[1] == "serve" {
		serve()
		return
	}
	if len(os.Args) > 1 && os.Args[1] == "check" {
		b, e := io.ReadAll(os.Stdin)
		if e != nil || len(b)%(width*8) != 0 {
			panic("invalid input")
		}
		r := make([]uint64, len(b)/8)
		for i := range r {
			r[i] = binary.LittleEndian.Uint64(b[i*8:])
		}
		out := calculate(r)
		b = make([]byte, len(out)*8)
		for i, v := range out {
			binary.LittleEndian.PutUint64(b[i*8:], v)
		}
		if _, e = os.Stdout.Write(b); e != nil {
			panic(e)
		}
		return
	}
	w := csv.NewWriter(os.Stdout)
	w.Write([]string{"carts", "lines", "repeat", "iterations", "ms", "checksum"})
	for _, lines := range []int{1, 8, 32} {
		for _, n := range []int{1, 16, 256, 4096, 65536, 262144, 1048576} {
			rows := fixture(n, lines)
			expected := calculate(rows)
			var checksum uint64
			for _, v := range expected {
				checksum += v
			}
			for warm := 0; warm < 8; warm++ {
				sink = calculate(rows)
			}
			iterations := 10
			if n < 4096 {
				iterations = 100
			}
			for rep := 0; rep < 3; rep++ {
				start := time.Now()
				for k := 0; k < iterations; k++ {
					sink = calculate(rows)
				}
				ms := float64(time.Since(start).Nanoseconds()) / 1e6 / float64(iterations)
				equal(sink, expected)
				w.Write([]string{strconv.Itoa(n), strconv.Itoa(lines), strconv.Itoa(rep), strconv.Itoa(iterations), fmt.Sprintf("%.9f", ms), strconv.FormatUint(checksum, 10)})
			}
			w.Flush()
		}
	}
	if w.Error() != nil {
		panic(w.Error())
	}
}
