package all

import (
	// activate file output writer
	_ "github.com/ncarlier/trackr/pkg/outputs/file"
	// activate prometheus output writer
	_ "github.com/ncarlier/trackr/pkg/outputs/prometheus"
)
