function RWR_mutated_gene = get_mutated_gene(G,snp,cnv,sample,gene)
%  screen key mutated genes using RWR and random reconnect
    
    % mutation information
    snp_samples = snp.textdata(1,2:end);
    snp_genes = snp.textdata(2:end,1);

    cnv_samples = cnv.textdata(1,2:end);
    cnv_genes = cnv.textdata(2:end,1);

    adj_matrix = full(adjacency(G));
    
    % obtain all mutated gene in personalized gene interaction network
    [~,index] = ismember(sample,snp_samples);
    snp_mutated = snp.data(:,index);
    [index,~] = ismember(snp_genes,gene);
    mutated.num = abs(snp_mutated(index));
    mutated.genes = snp_genes(index);
    mutated_snp = mutated.genes(mutated.num ~= 0);
    
    [~,index] = ismember(sample,cnv_samples);
    cnv_mutated = cnv.data(:,index);
    [index,~] = ismember(cnv_genes,gene);
    mutated.num = abs(cnv_mutated(index));
    mutated.genes = cnv_genes(index);
    mutated_cnv = mutated.genes(mutated.num ~= 0);

    mutated_gene = union(mutated_cnv,mutated_snp);
    [~,mutation] = ismember(mutated_gene,gene);
    
    % start RWR and random reconnect
    selected_mutated_gene = select_mutated_genes(adj_matrix,mutation);
    RWR_mutated_gene = gene(selected_mutated_gene,:);
                             
end