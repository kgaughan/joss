package system

import (
	"bytes"
	"log"
)

func logBytes(b []byte, prefix string) {
	if len(b) == 0 {
		return
	}
	for l := range bytes.SplitSeq(b, []byte("\n")) {
		log.Printf("[DEBUG]%s %s", prefix, l)
	}
}
