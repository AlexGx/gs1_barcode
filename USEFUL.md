https://ref.gs1.org/ai/
https://ref.gs1.org/standards/genspecs/

https://github.com/msupply-foundation/open-msupply/blob/c0484b06af58315782ff1c9ddba98877c2cb7dca/server/util/src/gs1.rs#L51
https://github.com/msupply-foundation/open-msupply/issues/6848
https://github.com/msupply-foundation/open-msupply/issues/5364

# todo:
- more explain on parser & test cases
- main module most used funcs
- why choose? section
- to_key?
- add bang! version where needed


- more test cases to tokenizer/parser:
When FNC1 is NOT PERMITTED
❌ After a fixed-length Application Identifier (AI)
❌ At the end of the data string
❌ Two consecutive FNC1 characters
❌ Within the data content of an AI
Any of the above constitutes a violation of the GS1 General Specifications.