#!/usr/bin/env python3

# TODO implement tiberius


rule tiberius_dummy_rule:
    input:
        unpack(annotation_tool_input_dict),
    output:
        touch(Path("results", "run", "{genome}", "tiberius", "tiberius.gtf")),
