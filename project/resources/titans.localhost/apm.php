 <?php
return [
    'serverUrl'             => 'http://apm-server:8200',
    'enabled'               => true,
    'transactionSampleRate' => 1, // Decimal, 0 to 1 .. e.g. 0.5 = 50% of transactions traced, 1 = 100%.
    'serviceName'           => 'titans', // Overridden by $_SERVER['HTTP_HOST'], special characters replaced with hyphens.
    'hostname'              => 'localhost', // Overridden by $_SERVER['HOSTNAME'].
    'environment'           => 'local',
    'stackTraceLimit'       => 2000,
    /*'secretToken'           => null,
    'serviceVersion'        => null,
    'frameworkName'         => 'magento2',
    'frameworkVersion'      => '2.4.5-p1',
    'timeout'               => 10,*/
];
