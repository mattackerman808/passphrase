#!/bin/bash

# Secure passphrase generator using EFF's large wordlist
# EFF Diceware list: 7,776 carefully chosen words
# 4 words = ~51 bits of entropy (would take centuries to crack)

WORDLIST_URL="https://www.eff.org/files/2016/07/18/eff_large_wordlist.txt"
WORDLIST_CACHE="/tmp/eff_wordlist.txt"
FALLBACK_WORDLIST="/tmp/fallback_wordlist.txt"

# Default values
COUNT=1
WORDS_PER=4

# Parse command line options
while getopts "n:w:h" opt; do
  case $opt in
    n)
      COUNT=$OPTARG
      ;;
    w)
      WORDS_PER=$OPTARG
      ;;
    h)
      echo "Usage: $0 [-n num_passphrases] [-w words_per_passphrase]"
      echo "  -n: Number of passphrases to output (default: 1)"
      echo "  -w: Number of words per passphrase (default: 4)"
      echo "  -h: Show this help message"
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      echo "Use -h for help"
      exit 1
      ;;
  esac
done

# Function to create fallback wordlist from system dictionary
create_fallback_wordlist() {
    echo "Creating fallback wordlist from system dictionary..."
    if [ -f /usr/share/dict/words ]; then
        # Filter for common, easy-to-spell words (4-8 letters, lowercase only)
        grep -E '^[a-z]{4,8}$' /usr/share/dict/words | \
        grep -v "'s$" | \
        head -7776 > "$FALLBACK_WORDLIST"
        echo "Fallback wordlist created with $(wc -l < "$FALLBACK_WORDLIST") words"
    else
        echo "Error: No wordlist available. Cannot generate passphrases."
        exit 1
    fi
}

# Download wordlist if not cached or older than 30 days
if [ ! -f "$WORDLIST_CACHE" ] || [ $(find "$WORDLIST_CACHE" -mtime +30 2>/dev/null) ]; then
    echo "Downloading EFF wordlist (7,776 words)..."

    # Try to download with curl (bypassing proxy if needed)
    if command -v curl &> /dev/null; then
        # Try without proxy first
        curl -s --noproxy "*" "$WORDLIST_URL" -o "$WORDLIST_CACHE" 2>/dev/null
        if [ $? -ne 0 ]; then
            # Try with proxy
            curl -s "$WORDLIST_URL" -o "$WORDLIST_CACHE" 2>/dev/null
        fi
    elif command -v wget &> /dev/null; then
        wget -q --no-proxy "$WORDLIST_URL" -O "$WORDLIST_CACHE" 2>/dev/null
        if [ $? -ne 0 ]; then
            wget -q "$WORDLIST_URL" -O "$WORDLIST_CACHE" 2>/dev/null
        fi
    fi

    # Check if download was successful
    if [ ! -s "$WORDLIST_CACHE" ]; then
        echo "Warning: Could not download EFF wordlist. Using fallback."
        create_fallback_wordlist
        WORDLIST_CACHE="$FALLBACK_WORDLIST"
    else
        echo "EFF wordlist downloaded and cached."
        # Extract just the words (EFF list has dice rolls in first column)
        awk '{print $2}' "$WORDLIST_CACHE" > "${WORDLIST_CACHE}.words"
        mv "${WORDLIST_CACHE}.words" "$WORDLIST_CACHE"
    fi
fi

# Load words into array
WORDS=($(cat "$WORDLIST_CACHE"))
WORD_COUNT=${#WORDS[@]}

# Calculate entropy
ENTROPY=$(echo "l($WORD_COUNT^$WORDS_PER)/l(2)" | bc -l | xargs printf "%.1f")

# Determine how many passphrases to generate (10x requested, or 100 if requesting 1)
if [ $COUNT -eq 1 ]; then
  GENERATE_COUNT=100
else
  GENERATE_COUNT=$((COUNT * 10))
fi

echo "Generating $COUNT passphrase(s) with $WORDS_PER words each:"
echo "Word list size: $WORD_COUNT words"
echo "Entropy per passphrase: ~${ENTROPY} bits"
echo "(Generating $GENERATE_COUNT candidates and selecting $COUNT randomly)"
echo ""

# Generate all passphrases into an array
PASSPHRASES=()
for ((i=1; i<=$GENERATE_COUNT; i++)); do
  passphrase=""
  for ((j=1; j<=$WORDS_PER; j++)); do
    # Use /dev/urandom for cryptographically secure randomness
    word_index=$(($(od -An -N2 -tu2 /dev/urandom | tr -d ' ') % WORD_COUNT))
    word=${WORDS[$word_index]}
    if [ $j -eq 1 ]; then
      passphrase="$word"
    else
      passphrase="$passphrase-$word"
    fi
  done
  PASSPHRASES+=("$passphrase")
done

# Randomly select and output the requested number of passphrases
SELECTED_INDICES=()
for ((i=1; i<=$COUNT; i++)); do
  # Generate random index and ensure it's unique
  while true; do
    random_index=$(($(od -An -N2 -tu2 /dev/urandom | tr -d ' ') % GENERATE_COUNT))
    # Check if this index was already selected
    duplicate=false
    for idx in "${SELECTED_INDICES[@]}"; do
      if [ $idx -eq $random_index ]; then
        duplicate=true
        break
      fi
    done
    if [ "$duplicate" = false ]; then
      SELECTED_INDICES+=($random_index)
      break
    fi
  done
  printf "%2d. %s\n" $i "${PASSPHRASES[$random_index]}"
  echo
done
