rule picard_intervals:
    input:
        ref = config["refGenomeDir"] + "{refGenome}.fna",
        fai = config["refGenomeDir"] + "{refGenome}.fna" + ".fai",
        dictf = config["refGenomeDir"] + "{refGenome}" + ".dict",
    output:
        intervals = temp(config['output'] + "{Organism}/{refGenome}/" + config["intDir"] + "{refGenome}_output.interval_list")
    params:
        minNmer = int(config['minNmer'])
    conda:
        "../envs/bam2vcf.yml"
    log:
        "logs/{Organism}/{refGenome}/picard_intervals/log"
    resources: 
        mem_mb = lambda wildcards, attempt: attempt * res_config['process_ref']['mem']   
    shell:
        "picard ScatterIntervalsByNs REFERENCE={input.ref} OUTPUT={output.intervals} MAX_TO_MERGE={params.minNmer} > {log}\n" 

checkpoint create_intervals:
    input:
        fai = config["refGenomeDir"] + "{refGenome}.fna" + ".fai",
        dictf = config["refGenomeDir"] + "{refGenome}" + ".dict",
        ref = config["refGenomeDir"] + "{refGenome}.fna",
        intervals = config['output'] + "{Organism}/{refGenome}/" + config["intDir"] + "{refGenome}_output.interval_list"
    params:
        maxIntervalLen = int(config['maxIntervalLen']),
        maxBpPerList = int(config['maxBpPerList']),
        maxIntervalsPerList = int(config['maxIntervalsPerList']),
        minNmer = int(config['minNmer'])
    output: 
        config['output'] + "{Organism}/{refGenome}/" + config["intDir"] + "{refGenome}_intervals_fb.bed"
    resources: 
        mem_mb = lambda wildcards, attempt: attempt * res_config['create_intervals']['mem'] 
    run:
        LISTS = helperFun.createListsGetIndices(params.maxIntervalLen, params.maxBpPerList, params.maxIntervalsPerList, params.minNmer, config["output"], config["intDir"], wildcards, input.dictf, input.intervals)
