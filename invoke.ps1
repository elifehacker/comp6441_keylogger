$id = 1
$val = 2
$params = @"
{
  "operation": "echo",
  "payload": {
    "somekey1": "$id",
    "somekey2": "$val"
  }
}
"@

echo $params

Invoke-WebRequest -Uri https://95rns5uaqf.execute-api.us-west-2.amazonaws.com/default/LambdaFunctionOverHttps/dynamodbmanager -ContentType "application/json" -Method POST -Body $params 