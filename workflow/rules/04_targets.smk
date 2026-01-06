for tool in all_tools:

    rule:
        name:
            f"{tool}_target"
        input:
            get_all_tool_results(tool),


for genome in all_genomes:

    rule:
        name:
            f"{genome}_target"
        input:
            get_all_genome_results(genome),
