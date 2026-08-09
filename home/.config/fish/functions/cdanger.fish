function cdanger
    codex --model 'gpt-5.5' -c 'model_reasoning_effort="high"' --dangerously-bypass-approvals-and-sandbox $argv
end
