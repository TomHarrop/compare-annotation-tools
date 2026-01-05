genomes_dict = config["genomes"]
tools_dict = config["tools"]
utils = config["utils"]
qc_tools_dict = config["qc"]
tiberius_models = tools_dict["tiberius"]["models"].keys()
helixer_lineages = tools_dict["helixer"]["lineages"]


all_genomes = sorted(set(genomes_dict.keys()))
all_busco_lineages = sorted(set(gd["busco_lineage"] for gd in genomes_dict.values()))
all_tools = sorted(set(tools_dict.keys()))
all_result_files = list(
    rf for td in tools_dict.values() for rf in td.get("result_files", [])
)

qc_result_files = list(
    rf for td in qc_tools_dict.values() for rf in td.get("result_files", [])
)


wildcard_constraints:
    busco_lineage="|".join(all_busco_lineages),
    genome="|".join(all_genomes),
    helixer_lineage="|".join(helixer_lineages),
    qc_file="|".join(qc_result_files),
    result_file="|".join(all_result_files),
    tiberius_model="|".join(tiberius_models),
    tool="|".join(all_tools),
