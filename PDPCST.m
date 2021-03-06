function [personalized_driver_symbol,personalized_driver_rank] = ... 
            PDPCST(ppi,expression_normal,expression_tumor,cnv_filename,snp_filename,pathway)
%  PDPCST outputs the patient-specific driver profiles
%  Input:
%         ppi: ppi network information
%         cnv_fileName,snp_fileName: mutation profiles(CNV and SNP)
%         expression_normal & expression_tumor: expression profiles (normal and normal) 
%         pathway: pathway data
%  Output:
%         personalized_driver: patient-specific driver profiles(0:non-driver; n(>=1):driver gene rank)
 
    [tumor,~,~] = importdata(expression_tumor);
    tumor_data = tumor.data;
    samples = tumor.textdata(1,2:end);
    gene_list = tumor.textdata(2:end,1);    
    [normal,~,~] = importdata(expression_normal);
    normal_data = normal.data;
    
    snp = importdata(snp_filename); 
    snp_samples = snp.textdata(1,2:end);
    snp_genes = snp.textdata(2:end,1);
    
    cnv = importdata(cnv_filename); 
    cnv_samples = cnv.textdata(1,2:end);
    cnv_genes = cnv.textdata(2:end,1);
    
    mutated_samples = intersect(snp_samples,cnv_samples);
    mutation = union(snp_genes,cnv_genes);
    mutation = intersect(mutation,gene_list);
    
%     for i = 1 : size(tumor_data,2) 
    for i = 1 : 2
        [~,index] = ismember(samples(:,i),mutated_samples);
        if index ~= 0
            
            % construct personalized gene interaction network
            sample_tumor = tumor_data(:,i);        
            sample_normal = normal_data(:,i);
            [gene,edge] = construct_network(ppi,gene_list,normal_data,sample_normal,sample_tumor);
            net.gene = [gene(edge(:,1)) gene(edge(:,2))];
            net.w = edge(:,3); 
            
            gene1 = edge(:,1);  gene2 = edge(:,2);
            N1 = length(gene1); N2 = length(gene);
            Net = zeros(N2);
            for j = 1 : N1    
                Net(gene1(j,1),gene2(j,1)) = net.w(j,1);  %undirected gene-gene interaction network
            end        
            G1 = tril(Net);
            [g1,g2] = find(G1 ~= 0);
            G = graph(g1,g2);
            D = degree(G);
            
            RWR_mutated_gene = get_mutated_gene(G,snp,cnv,samples(i),gene);
            hub_mutated_gene = gene(D > mean(D),:);
            mutated_gene = intersect(RWR_mutated_gene,hub_mutated_gene);
                       
            if ~isempty(mutated_gene)            
                
            %   node weight              
                beta = 1;      % FC    
                value = 0.01 * ones(length(sample_normal),1);
                node = abs(log2((sample_tumor + value) ./ (sample_normal + value)));             
                [~,index] = ismember(gene,gene_list);       
                node = node(index);
                DEG = gene(node > beta); 
                node = node(node > beta);
                
             %  calculate influence score  
                influence_score = mutation_dysregulation_network(pathway,DEG,D,node,net,mutated_gene);
             %  personalized ranking
                influence_score_total = sum(influence_score,1);
                mutated_gene(influence_score_total == 0,:) = [];
                influence_score_total(:,influence_score_total == 0) = [];
                [~,id] = sort(influence_score_total,'descend');
                driver = mutated_gene(id);
                
                [~,index] = ismember(mutation,driver);
                personalized_driver_rank(:,i) = index;
            end       
        end                     
    end
    zero = sum(personalized_driver_rank == 0,2) == size(personalized_driver_rank,2);
    personalized_driver_rank(zero,:) = [];
    mutation(zero,:) = [];
    personalized_driver_symbol = mutation;
end