/// Display names that used to sound like a trade signal.
const legacyStrategyNames = {'급등주': '수익성'};

const profitabilityPresetName = '수익성';

String canonicalStrategyName(String name) => legacyStrategyNames[name] ?? name;
