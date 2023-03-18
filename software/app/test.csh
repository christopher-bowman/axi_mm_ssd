#!/bin/tcsh
set digits = (126 48 109 121 51 91 31 112 127 115)
set delay = $argv[1]
foreach tens ($digits)
  sysctl dev.ssd.0.tens=$tens
  foreach ones ($digits)
    sysctl dev.ssd.0.ones=$ones
    sleep $delay
  end
end
