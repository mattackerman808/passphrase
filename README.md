# Passphrase Generator

A secure passphrase generator using the [EFF's large wordlist](https://www.eff.org/deeplinks/2016/07/new-wordlists-random-passphrases) for creating memorable, cryptographically strong passphrases.

## Features

- **Secure randomness**: Uses `/dev/urandom` for cryptographically secure random number generation
- **High entropy**: 4-word passphrases provide ~51 bits of entropy
- **EFF wordlist**: Uses carefully curated 7,776-word list optimized for memorability and security
- **Fallback support**: Automatically uses system dictionary if EFF wordlist download fails
- **Smart selection**: Generates 10x the requested passphrases (or 100 for single requests) and randomly selects from the pool
- **Flexible options**: Customize number of passphrases and words per passphrase

## Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/passphrase.git
cd passphrase
```

2. Make the script executable:
```bash
chmod +x generate_passphrases.sh
```

3. Run the script:
```bash
./generate_passphrases.sh
```

## Usage

```bash
./generate_passphrases.sh [-n num_passphrases] [-w words_per_passphrase] [-h]
```

### Options

- `-n NUM`: Number of passphrases to output (default: 1)
- `-w NUM`: Number of words per passphrase (default: 4)
- `-h`: Show help message

### Examples

Generate a single passphrase with 4 words (generates 100 candidates, picks 1):
```bash
./generate_passphrases.sh
```

Generate 5 passphrases with 4 words each (generates 50 candidates, picks 5):
```bash
./generate_passphrases.sh -n 5
```

Generate a single passphrase with 6 words for extra security:
```bash
./generate_passphrases.sh -w 6
```

Generate 3 passphrases with 5 words each:
```bash
./generate_passphrases.sh -n 3 -w 5
```

## Example Output

```
Generating 1 passphrase(s) with 4 words each:
Word list size: 7776 words
Entropy per passphrase: ~51.7 bits
(Generating 100 candidates and selecting 1 randomly)

 1. cosmic-hedgehog-envelope-atlas
```

## Security Notes

- **Entropy**: A 4-word passphrase from the EFF wordlist provides approximately 51.7 bits of entropy, which would take centuries to crack with current technology
- **Randomness**: The script uses `/dev/urandom` for cryptographically secure random number generation
- **Word selection**: Generates 10x the requested number of passphrases (minimum 100) and randomly selects to ensure high-quality randomness
- **No predictable patterns**: Each word is selected independently with true randomness

### Recommended Usage

- **4 words**: Good for most online accounts (~51 bits entropy)
- **5 words**: Better for sensitive accounts (~64 bits entropy)
- **6 words**: Recommended for encryption keys (~77 bits entropy)
- **7+ words**: Maximum security for critical systems (~90+ bits entropy)

## Requirements

- Bash shell
- `/dev/urandom` (standard on Linux/macOS/Unix)
- `curl` or `wget` (for downloading the wordlist)
- `bc` (for entropy calculation)

## How It Works

1. Downloads and caches the EFF large wordlist (7,776 words)
2. If download fails, creates a fallback wordlist from `/usr/share/dict/words`
3. Generates 10x the requested number of passphrases (or 100 for single requests)
4. Randomly selects the requested number from the generated pool
5. Words are joined with hyphens for easy reading and typing

## License

MIT License - Feel free to use and modify as needed.

## Credits

- Wordlist: [Electronic Frontier Foundation (EFF)](https://www.eff.org/deeplinks/2016/07/new-wordlists-random-passphrases)
- Inspired by the [Diceware](https://theworld.com/~reinhold/diceware.html) passphrase system
