# fylr-plugin-custom-data-type-weblink

A [fylr](https://docs.fylr.io) plugin providing the custom data type **`link`**
("Weblink"): store internet links in your records, with link validation,
automatic top-level-domain extraction, an optional localized link text and
configurable link templates.

A `link` value indexes and searches by its parts: the URL itself, the plain
link text, the top-level domain and the localized text.

## Installation

Open the fylr Plugin Manager and add a new plugin of type "url". This URL
always links to the latest released version:

```
https://github.com/programmfabrik/fylr-plugin-custom-data-type-weblink/releases/latest/download/fylr-plugin-custom-data-type-weblink.zip
```

## Configuration

**Datamodel (schema) options** — per field of type `link`:

* *title*: how the link title is stored — `none`, `text` (plain) or
  `text-l10n` (localized)
* *add timestamp*: whether each link carries a timestamp

**Mask options** — per mask:

* *editor style*: edit the link `inline` or in a `popover`

**Base configuration** (system settings → Weblink): reusable **link
templates**. A template has a localized name, a URL pattern (validated as
`http(s)://…`) with **placeholders**, and a localized display name — editors
pick a template and only fill in the placeholder values.

## Building

Built by [fylr-build-plugin](https://github.com/programmfabrik/fylr-build-plugin);
run `make` for the target list (`make build` assembles `build/custom-data-type-link/`,
loadable by fylr from disk for development). The loca CSV is mastered in a
Google Sheet — edit there and run `make loca`, never edit the CSV directly.

## Contact

For issues and questions please use
[the issue tracker](https://github.com/programmfabrik/fylr-plugin-custom-data-type-weblink/issues)
or write to support@programmfabrik.de.

---

*This plugin was forked for fylr from
[easydb-custom-data-type-link](https://github.com/programmfabrik/easydb-custom-data-type-link),
which continues to serve easydb 5 unchanged. The plugin name
`custom-data-type-link` and the datamodel mapping are identical, so existing
datamodels work with either.*
