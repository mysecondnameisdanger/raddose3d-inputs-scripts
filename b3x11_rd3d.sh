#!/bin/bash

JAR_PATH="/home/mcarrera/murphy/doc/repos/r3d/raddose3d.jar"
SEQ_PATH="/home/mcarrera/murphy/doc/seq/1iee.fasta"
DIR_PATH="/home/mcarrera/murphy/doc/dose/r3d"

if [ ! -f "$JAR_PATH" ]; then
  echo "ERROR: JAR file not found at $JAR_PATH"
  exit 1
fi

cd ${DIR_PATH}

for dataset in $(seq -w 01 20); do
  dir="b3x11_${dataset}w"
  mkdir "$dir"

  cat > "$dir/input.txt" << EOF
CRYSTAL
Type Cuboid
Dimensions 240 240 240
PixelsPerMicron 0.5
AbsCoefCalc Sequence
UnitCell 78.75 78.75 36.95
SeqFile $SEQ_PATH
NumMonomers 8
SolventHeavyConc P 54.7 Cl 427.8 Na 496.8
BEAM
Type Gaussian
Flux 4.8e11
Fwhm 64 19
Energy 12.66
Collimation Circular 200 200
EOF

  num=${dataset#0}
  for ((j=1; j<=num; j++)); do
    if (( j % 2 == 1 )); then
      cat >> "$dir/input.txt" << 'EOF'

WEDGE 0 45
AngularResolution 0.5
ExposureTime 9
EOF
    else
      cat >> "$dir/input.txt" << 'EOF'
WEDGE 90 135
AngularResolution 0.5
ExposureTime 9
EOF
    fi
  done
done

for dir in b3x11_*/; do
  cd "$dir" || continue
  java -Xmx300G -jar "$JAR_PATH" -i input.txt > out.log 2>&1
  find . -name "out*csv" -exec xz -T0 -9 {} +
  cd ..
done
