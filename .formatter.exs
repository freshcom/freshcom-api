[
  # functions to let allow the no parens like def print value
  locals_without_parens: [
    field: 2,
    field: 3,
    belongs_to: 2,
    belongs_to: 3,
    has_many: 2,
    has_many: 3,
    has_one: 2,
    has_one: 3
  ],

  # files to format
  inputs: ["mix.exs", "{config,lib,test}/**/*.{ex,exs}"]
]