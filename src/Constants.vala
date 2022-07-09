using Gtk;
using Gdk;

namespace ThiefMD {
    public enum Target {
        STRING,
        URI
    }

    public const TargetEntry[] target_list = {
        { "STRING" , 0, Target.STRING },
        { "text/uri-list", 0, Target.URI }
    };

    public static void save_file (File save_file, uint8[] buffer) throws Error {
        var output = new DataOutputStream (save_file.create(FileCreateFlags.REPLACE_DESTINATION));
        long written = 0;
        while (written < buffer.length)
            written += output.write (buffer[written:buffer.length]);
    }

    public const string c = """#include <stdio.h>
// Write a function
int main() {
    // Say hello
    printf("Hello World!");
    return 0;
}""";

    public const string cs = """class Hello {
    // Write a method
    public static void Main(string[] args) {
        // Say hello
        Console.WriteLine("Hello World!");
    }
}""";

    public const string py = """# Declare a function
def main():
    # Say hello to the world
    print "Hello World!"
""";

    public const string rust = """// This is the main function
fn main() {
    // Print text to the console
    println!("Hello World!");
}""";

    public const string html = """<html>
    <head>
        <!-- Set a title -->
        <title>Hello World!</title>
    </head>
    <body>
        <!-- Display some text -->
        <h1 id="title">Hello World!</h1>
    </body>
</html>""";

    public const string IPSUM = """---
title: This is Sample YAML
tags: filler, sample, example
---

# This is a Preview File

It will be used for sanity checking the style-sheet used.

*Emphasized* text.

**Strong** text.

[Link to page](https://thiefmd.com)

## Lists

1. First item
2. Second item
3. Third item

> Block Quote
> - Famous Amos

* First item
* `Second` item
* Third item

***

```vala
    switch (target_type) {
        case Target.STRING:
            selection_data.set (
                selection_data.get_target(),
                BYTE_BITS,
                (uchar [])_sheet_path.to_utf8());
        break;
        default:
            warning ("No known action to take.");
        break;
    }
```

### Markdown Rendered Image

![](/images/matt-hoffman-wheat.jpg)

### Tables

| Syntax | Description |
| ----------- | ----------- |
| Header | Title |
| Paragraph | Text | 

Here's a sentence with a footnote. [^1]

I'm basically ~~stealing~~ copying and pasting examples from [https://www.markdownguide.org/cheat-sheet](https://www.markdownguide.org/cheat-sheet).

[^1]: This is the footnote.

### Math

$$\int_{a}^{b} x^2 dx$$
""";
}