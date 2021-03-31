package main

import "fmt"

func assert(cond bool, format string, args ...interface{}) {
	if cond {
		return
	}
	err := fmt.Sprintf(format, args...)
	panic(err)
}

func logf(format string, args ...interface{}) {
	if len(args) == 0 {
		fmt.Print(format)
		return
	}
	fmt.Printf(format, args...)
}
