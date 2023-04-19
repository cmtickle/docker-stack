module.exports = {
    ci: {
        collect: {
            numberOfRuns: 1,
            url: ['http://eg-m2-commerce.local/',
                'https://eg-m2-commerce.local/women/tops-women.html',
                'https://eg-m2-commerce.local/breathe-easy-tank.html' ],
            settings: {
                onlyCategories: ['performance', 'accessibility', 'best-practices', 'seo'],
                disableStorageReset: true,
                formFactor: 'desktop',
                screenEmulation: {
                    disabled: true
                },
                locale: 'en-GB',
                throttling: {rttMs: 40, throughputKbps: 10 * 1024, cpuSlowdownMultiplier: 1},
                chromeFlags: '--ignore-certificate-errors --no-sandbox --disable-dev-shm-usage --headless',
                maxWaitForFcp: 60 * 1000,
                maxWaitForLoad: 60 * 1000,
                skipAudits: ['uses-http2'],
            }
        },
        upload: {
            serverBaseUrl: 'http://127.0.0.1:9001',
            token:  ''
        }
    }
};
