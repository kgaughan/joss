package matchers

import (
	"encoding/json"

	"github.com/onsi/gomega/matchers"
	"github.com/samber/lo"
)

type ContainElementsMatcher struct {
	matchers.ContainElementsMatcher
}

func ContainElements(elements ...any) GossMatcher {
	return &ContainElementsMatcher{
		matchers.ContainElementsMatcher{
			Elements: elements,
		},
	}
}

func (m *ContainElementsMatcher) FailureResult(actual any) MatcherResult {
	missingElements := getUnexported(m, "missingElements")
	missingEl, ok := missingElements.([]any)
	var foundElements any
	if ok {
		foundElements, _ = lo.Difference(m.Elements, missingEl)
	}
	return MatcherResult{
		Actual:          actual,
		Message:         "to contain elements matching",
		Expected:        m.Elements,
		MissingElements: missingElements,
		FoundElements:   foundElements,
	}
}

func (m *ContainElementsMatcher) NegatedFailureResult(actual any) MatcherResult {
	return MatcherResult{
		Actual:   actual,
		Message:  "not to contain elements matching",
		Expected: m.Elements,
	}
}

func (m *ContainElementsMatcher) MarshalJSON() ([]byte, error) {
	j := make(map[string]any)
	j["contain-elements"] = m.Elements
	return json.Marshal(j)
}
