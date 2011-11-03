function [state error] = get_opt_state(values, new_val)

[error state]=min(abs(values-new_val));