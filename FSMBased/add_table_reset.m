function [table errors] = add_table_reset(values, weight)

table = zeros(size(values));
errors = zeros(size(values));

for i=1:length(table)
    [table(i) errors(i)] = get_opt_state(values, values(i)+weight);
    if table(i) == length(table)
        table(i) = 1;
    end
end