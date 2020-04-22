CREATE OR REPLACE FUNCTION
    `blockchain-etl.ethereum_ens_internal.parse_Registrar0_event_NewBid`(data STRING, topics ARRAY<STRING>)
    RETURNS STRUCT<>
    LANGUAGE js AS """
    var abi = {"anonymous": false, "inputs": [{"indexed": true, "name": "hash", "type": "bytes32"}, {"indexed": true, "name": "bidder", "type": "address"}, {"indexed": false, "name": "deposit", "type": "uint256"}], "name": "NewBid", "type": "event"}

    var interface_instance = new ethers.utils.Interface([abi]);

    var parsedLog = interface_instance.parseLog({topics: topics, data: data});

    var parsedValues = parsedLog.values;

    var transformParams = function(params, abiInputs) {
        var result = {};
        if (params && params.length >= abiInputs.length) {
            for (var i = 0; i < abiInputs.length; i++) {
                var paramName = abiInputs[i].name;
                var paramValue = params[i];
                if (abiInputs[i].type === 'address' && typeof paramValue === 'string') {
                    // For consistency all addresses are lower-cased.
                    paramValue = paramValue.toLowerCase();
                }
                if (ethers.utils.Interface.isIndexed(paramValue)) {
                    paramValue = paramValue.hash;
                }
                if (abiInputs[i].type === 'tuple' && 'components' in abiInputs[i]) {
                    paramValue = transformParams(paramValue, abiInputs[i].components)
                }
                result[paramName] = paramValue;
            }
        }
        return result;
    };

    var result = transformParams(parsedValues, abi.inputs);

    return result;
"""
OPTIONS
  ( library="gs://blockchain-etl-bigquery/ethers.js" );