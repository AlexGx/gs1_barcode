# GS1 barcode lib for parsing, validation and formatting

![GS1Barcode](https://raw.githubusercontent.com/AlexGx/gs1_barcode/master/artwork/banner.jpg)

<p>
  <a href="https://hex.pm/packages/gs1_barcode">
    <img alt="Hex Version" src="https://img.shields.io/hexpm/v/gs1_barcode.svg">
  </a>
  <a href="https://hexdocs.pm/gs1_barcode">
    <img src="https://img.shields.io/badge/docs-hexdocs-blue" alt="HexDocs">
  </a>
  <a href="https://github.com/AlexGx/gs1_barcode/actions">
    <img alt="CI Status" src="https://github.com/AlexGx/gs1_barcode/workflows/ci/badge.svg">
  </a>
</p>


## Installation
Add `gs1_barcode` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:gs1_barcode, "~> 0.1.0"}
  ]
end
```

GS1 barcode requires Elixir 1.16 or later, and OTP 25 or later. It may work with earlier versions, but it wasn't tested against them.


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `gs1_barcode` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:gs1_barcode, "~> 0.1.0"}
  ]
end
```

## Disclaimer

This software is an independent, open-source implementation and is **not affiliated with, endorsed by, sponsored by, or officially connected to GS1 AISBL or any of its member organizations** in any way.

### Trademark Notice

GS1®, GS1 DataMatrix®, GS1-128®, EAN®, UPC®, GTIN®, GLN®, SSCC®, and all related trademarks, service marks, logos, and trade names are the exclusive property of GS1 AISBL and/or its member organizations. All other trademarks are the property of their respective owners. The use of these trademarks in this project is solely for identification and informational purposes and does not imply any affiliation, endorsement, or sponsorship.

### Standards Compliance

This implementation is based on publicly available GS1 General Specifications and related documentation. While every effort has been made to ensure accuracy and compliance with GS1 standards, this software is provided without any guarantee of correctness, completeness, or fitness for any particular purpose.

**This implementation has not been certified, validated, or approved by GS1.**

Users requiring official GS1 compliance certification should contact GS1 directly or consult with an accredited GS1 Solution Provider.

### Limitation of Liability

The authors and contributors of this software shall not be held liable for any direct, indirect, incidental, special, exemplary, or consequential damages (including, but not limited to, procurement of substitute goods or services, loss of use, data, or profits, or business interruption) however caused and on any theory of liability, whether in contract, strict liability, or tort (including negligence or otherwise) arising in any way out of the use of this software, even if advised of the possibility of such damage.

### User Responsibility

Users of this software are solely responsible for ensuring that their use complies with all applicable laws, regulations, industry standards, and GS1 membership requirements. Users should independently verify the accuracy and validity of any barcodes generated or parsed by this software before use in production environments.

---

For official GS1 standards, specifications, and membership information, please visit [https://www.gs1.org](https://www.gs1.org).
