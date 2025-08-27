#!/usr/bin/env bash

echo "YOLOv9 to ONNX export"
echo "https://github.com/beardedtek/frigate-config"
echo ""

MODEL_SIZES=(t s m c e)
IMAGE_SIZES=(160 320 480 640)

DEFAULT_MODEL="t"
DEFAULT_IMAGE="320"
DEFAULT_OUTPUT="."

# Model info arrays (index matches MODEL_SIZES)
MODEL_PARAMS=("58M" "90M" "110M" "51M" "120M")
MODEL_INFERENCE=("23 ms" "25 ms" "28 ms" "30 ms" "32 ms")
MODEL_DESC=(
  "Fastest, smallest model. Great for edge devices, lower accuracy."
  "Balanced speed and accuracy. Good general-purpose choice."
  "Higher accuracy, slower. Use if quality matters more than speed."
  "Compact model, fewer parameters. Moderate speed and accuracy."
  "Largest model, highest accuracy, slower inference."
)

usage() {
  echo "Usage: $0 [-m model_size] [-i image_size] [-o output_dir]"
  echo
  echo "Options:"
  echo "  -m    Model size   (${MODEL_SIZES[*]})"
  echo "  -i    Image size   (${IMAGE_SIZES[*]})"
  echo "  -o    Output directory (default: current directory)"
  echo
  echo "If not provided, you will be prompted (defaults: model=$DEFAULT_MODEL, image=$DEFAULT_IMAGE, output=$DEFAULT_OUTPUT)"
  exit 1
}

# Defaults
OUTPUT_DIR="$DEFAULT_OUTPUT"

# Parse flags
while getopts "m:i:o:h" opt; do
  case $opt in
    m) MODEL_SIZE="$OPTARG" ;;
    i) IMAGE_SIZE="$OPTARG" ;;
    o) OUTPUT_DIR="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

# Validation helpers
valid_choice() {
  local value=$1; shift
  local options=("$@")
  for o in "${options[@]}"; do
    [[ "$o" == "$value" ]] && return 0
  done
  return 1
}

# Enhanced menu chooser with default + model info
choose_model() {
  local __resultvar="$1"; shift
  local default="$1"

  echo
  echo "Select Model Size:"
  for i in "${!MODEL_SIZES[@]}"; do
    echo "  $((i+1))) ${MODEL_SIZES[$i]} | Params: ${MODEL_PARAMS[$i]}, Inference: ${MODEL_INFERENCE[$i]}"
    echo "         ${MODEL_DESC[$i]}"
    echo ""
  done
  echo "Press Enter to use default: $default"

  local choice
  while true; do
    read -r -p "Enter choice [1-${#MODEL_SIZES[@]}]: " choice
    if [[ -z "$choice" ]]; then
      printf -v "$__resultvar" '%s' "$default"
      return
    elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#MODEL_SIZES[@]} )); then
      printf -v "$__resultvar" '%s' "${MODEL_SIZES[$((choice-1))]}"
      return
    fi
    echo "Invalid choice, try again."
  done
}

# Existing directory chooser
choose_directory() {
  local __resultvar="$1"; shift
  local prompt="$1"; shift
  local default="$1"

  echo
  read -r -p "$prompt [default: $default]: " input
  if [[ -z "$input" ]]; then
    input="$default"
  fi

  if [[ ! -d "$input" ]]; then
    echo "Directory '$input' does not exist."
    read -r -p "Create it? [y/N]: " create
    if [[ "$create" =~ ^[Yy]$ ]]; then
      mkdir -p "$input"
      echo "Created directory: $input"
    else
      echo "Falling back to current directory: ."
      input="."
    fi
  fi

  printf -v "$__resultvar" '%s' "$input"
}

# Prompt for missing flags
if [[ -z "$MODEL_SIZE" ]]; then
  choose_model MODEL_SIZE "$DEFAULT_MODEL"
elif ! valid_choice "$MODEL_SIZE" "${MODEL_SIZES[@]}"; then
  echo "Invalid model size: $MODEL_SIZE"
  usage
fi

if [[ -z "$IMAGE_SIZE" ]]; then
  choose_option() {
    local __resultvar="$1"; shift
    local prompt="$1"; shift
    local default="$1"; shift
    local options=("$@")

    echo
    echo "$prompt"
    for i in "${!options[@]}"; do
      echo "  $((i+1))) ${options[$i]}"
    done
    echo "Press Enter to use default: $default"

    local choice
    while true; do
      read -r -p "Enter choice [1-${#options[@]}]: " choice
      if [[ -z "$choice" ]]; then
        printf -v "$__resultvar" '%s' "$default"
        return
      elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
        printf -v "$__resultvar" '%s' "${options[$((choice-1))]}"
        return
      fi
      echo "Invalid choice, try again."
    done
  }
  choose_option IMAGE_SIZE "Select Image Size:" "$DEFAULT_IMAGE" "${IMAGE_SIZES[@]}"
elif ! valid_choice "$IMAGE_SIZE" "${IMAGE_SIZES[@]}"; then
  echo "Invalid image size: $IMAGE_SIZE"
  usage
fi

if [[ "$OUTPUT_DIR" == "$DEFAULT_OUTPUT" ]]; then
  choose_directory OUTPUT_DIR "Enter output directory" "$DEFAULT_OUTPUT"
elif [[ ! -d "$OUTPUT_DIR" ]]; then
  echo "Directory '$OUTPUT_DIR' does not exist."
  read -r -p "Create it? [y/N]: " create
  if [[ "$create" =~ ^[Yy]$ ]]; then
    mkdir -p "$OUTPUT_DIR"
    echo "Created directory: $OUTPUT_DIR"
  else
    echo "Falling back to current directory: ."
    OUTPUT_DIR="."
  fi
fi

# Find index of selected model
for i in "${!MODEL_SIZES[@]}"; do
  if [[ "${MODEL_SIZES[$i]}" == "$MODEL_SIZE" ]]; then
    MODEL_INDEX=$i
    break
  fi
done

# Confirmation step with model info
echo
echo "Summary of selections:"
echo "  MODEL_SIZE=${MODEL_SIZE}"
echo "    Parameters: ${MODEL_PARAMS[$MODEL_INDEX]}"
echo "    Inference: ${MODEL_INFERENCE[$MODEL_INDEX]}"
echo "    Description: ${MODEL_DESC[$MODEL_INDEX]}"
echo "  IMAGE_SIZE=${IMAGE_SIZE}"
echo "  OUTPUT_DIR=${OUTPUT_DIR}"
echo
read -r -p "Proceed with exporting YOLOv9 model to ONNX? [y/N]: " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Build cancelled."
  exit 0
fi

# Run Docker build
echo
echo "Exporting YOLOv9 model to ONNX via docker"
docker build . \
  --build-arg MODEL_SIZE="${MODEL_SIZE}" \
  --build-arg IMAGE_SIZE="${IMAGE_SIZE}" \
  --output "${OUTPUT_DIR}"

