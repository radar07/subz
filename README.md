# subz - Subtitle Downloader

A fast, interactive CLI tool for downloading movie and TV show subtitles, written in Zig.

## Features

- 🔍 Search subtitles by IMDB ID
- 🌍 Support for multiple languages
- ⬆️⬇️ Interactive arrow-key menu for subtitle selection
- 📺 TV show support with season/episode selection
- 🎨 Colorized terminal output
- ⚡ Fast and lightweight (zero dependencies)
- 🔓 No authentication required

## Installation

### Build from source

```bash
zig build
```

The executable will be in `./zig-out/bin/subz`

## Usage

### Basic Usage

```bash
# Download English subtitles for a movie
subz tt0816692

# Download Spanish subtitles
subz tt0816692 -l es

# Download subtitles for a TV show episode
subz tt0944947 -s 1 -e 1  # Game of Thrones S01E01
```

### Command-Line Options

```
Usage: subz [OPTIONS] <imdb_id>

Arguments:
  <imdb_id>                IMDB ID (e.g., tt0133093 for The Matrix)

Options:
  -l, --language <LANG>    Language code (default: en)
                           Common: en, es, fr, de, pt, ko, ja, zh
  -s, --season <NUM>       Season number (for TV shows)
  -e, --episode <NUM>      Episode number (for TV shows)
  -h, --help               Show this help message
  -v, --version            Show version information
```

### Finding IMDB IDs

1. Go to [IMDb](https://www.imdb.com/)
2. Search for your movie or TV show
3. The IMDB ID is in the URL: `https://www.imdb.com/title/tt0816692/` → `tt0816692`

### Language Codes

Use ISO 639-1 two-letter language codes:

- `en` - English
- `es` - Spanish
- `fr` - French
- `de` - German
- `pt` - Portuguese
- `ko` - Korean
- `ja` - Japanese
- `zh` - Chinese
- And many more...

## Examples

```bash
# Interstellar (English)
subz tt0816692

# Parasite (Korean with English subtitles)
subz tt6751668 -l en

# The Matrix (Spanish)
subz tt0133093 -l es

# Breaking Bad S01E01 (English)
subz tt0959621 -s 1 -e 1
```

## How It Works

1. Enter the IMDB ID of the movie/show you want
2. The tool searches Wyzie Subs API for available subtitles
3. If multiple subtitles are found, an interactive menu appears
4. Use ↑/↓ arrow keys to select the subtitle you want
5. Press Enter to download
6. The subtitle file is saved in your current directory

## Technical Details

- **Language**: Zig 0.16.0-dev
- **Subtitle Source**: [Wyzie Subs API](https://sub.wyzie.ru/)
- **Supported Formats**: SRT, ASS, VTT
- **Terminal UI**: Custom ANSI escape code implementation (no external dependencies)

## Project Structure

```
subz/
├── src/
│   ├── main.zig              # Entry point & orchestration
│   ├── api/
│   │   ├── http_client.zig   # HTTP client wrapper
│   │   ├── wyzie.zig         # Wyzie Subs API integration
│   │   └── types.zig         # Data structures
│   ├── ui/
│   │   ├── terminal.zig      # Terminal control (raw mode, ANSI codes)
│   │   └── menu.zig          # Interactive menu with arrow keys
│   └── cli/
│       └── args.zig          # CLI argument parser
└── build.zig
```

## Known Limitations

- Wyzie Subs API may not have subtitles for very old or obscure movies
- The terminal UI requires a TTY (doesn't work with piped output)
- Some movies may return "No subtitles found" even if they exist on other sources

## Future Enhancements

- Support for additional subtitle sources (SubDL, OpenSubtitles)
- Search by movie title (not just IMDB ID)
- Batch download mode
- Custom filename templates
- Configuration file support

## License

MIT

## Credits

- Subtitle data provided by [Wyzie Subs](https://sub.wyzie.ru/)
- Built with [Zig](https://ziglang.org/)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
