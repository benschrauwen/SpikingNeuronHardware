function [table errors] = add_table_satur(values, weight)

table = zeros(size(values));
errors = zeros(size(values));

for i=1:length(table)
    [table(i) errors(i)] = get_opt_state(values, values(i)+weight);
end