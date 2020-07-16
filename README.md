# Gopherette

Gopherette is a simple Gopher and Gemini client for SailfishOS.

## Licence

Copyright (C) 2018 - Jérémy Farnaud

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see https://www.gnu.org/licenses/.

## Features

- Displaying native documents and images
- Bookmarks
- Opening external links in the browser
- Slide to go back to previous page
- Seemlessly navigate between protocols
- Queries

### Gopher specifics

- Heuristics based reflowing and formatting of Gopher pages in portrait mode
- Plain monospace text in landscape mode in 80 columns
- Supported selector types:
  - Menu
  - Text
  - Images
- Displays info for unsupported selector types

### Gemini specifics

- Server certificate pinning

## Limitations

- Some Gemini servers are not accessible because of TLS incompatibility between them and the TLS library used by SailfishOS which is a bit old as of july 2020.
- Only UTF-8 and Latin1 encodings are supported. Encoding is guessed for Gopher.
- Very large documents crash the app.

