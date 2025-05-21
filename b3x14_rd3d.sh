#!/bin/bash

JAR_PATH="/home/mcarrera/murphy/doc/repos/r3d/raddose3d.jar"
SEQ_PATH="/home/mcarrera/murphy/doc/seq/1iee.fasta"
DIR_PATH="/home/mcarrera/murphy/doc/dose/r3d"
OBJ_PATH="/home/mcarrera/murphy/doc/dose/blender/final_b3x14.obj"

if [ ! -f "$JAR_PATH" ]; then
  echo "ERROR: JAR file not found at $JAR_PATH"
  exit 1
fi

cd ${DIR_PATH}

for dataset in $(seq -w 01 20); do
  dir="b3x14_${dataset}w"
  mkdir "$dir"

  cat > "$dir/input.txt" << EOF
CRYSTAL
Type Polyhedron
WireFrameType obj
ModelFile $OBJ_PATH
Dimensions 100 100 100 # https://github.com/GarmanGroup/RADDOSE-3D/issues/19
PixelsPerMicron 0.5
AbsCoefCalc Sequence
UnitCell 78.22 78.22 37.15
SeqFile $SEQ_PATH
NumMonomers 8
SolventHeavyConc P 54.7 Cl 427.8 Na 572.6
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

for dir in b3x14_*/; do
  cd "$dir" || continue
  java -Xmx300G -jar "$JAR_PATH" -i input.txt > out.log 2>&1
  find . -name "out*csv" -exec xz -T0 -9 {} +
  cd ..
done
