#!/bin/bash

# 前準備
mkdir -p /tmp/benchmark
cd /tmp/benchmark || exit 1

# ベンチマークファイル作成
tee /tmp/benchmark/benchmark_test.go << "EOF"
// ベンチマーク走らせる
// $ go test -bench . -benchmem -run=none -benchtime=1s -count=10 -cpuprofile=cpu1.prof | tee bench1.log
// $ go test -bench . -benchmem -run=none -benchtime=1s -count=10 -cpuprofile=cpu2.prof | tee bench2.log
// $ benchstat bench1.log bench2.log  # go get -u golang.org/x/perf/cmd/benchstat
// $ go tool pprof -http=":8081" cpu.prof

// alloc と free のトレースを見る
// $ go test -c -o main.benchmark
// $ GODEBUG=allocfreetrace=1 ./main.benchmark -run=none -bench=BenchmarkAppendQuote > trace.log 2>&1

package benchmark_test

import (
	"strconv"
	"testing"
)

func BenchmarkAppendQuote(b *testing.B) {
	s := []byte{}

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		s = strconv.AppendQuote(s, `\"a\"`)
	}
}
EOF

