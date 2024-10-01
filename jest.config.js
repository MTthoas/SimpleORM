module.exports = {
    testMatch: ["**/tests/**/*.test.res.js"],
    transform: {
        "^.+\\.res\\.js$": "babel-jest",
    },
    moduleFileExtensions: ["js", "res"],
    collectCoverage: true,
    coverageDirectory: "coverage",
    coverageReporters: ["json", "lcov", "text", "clover"],
    transformIgnorePatterns: [
        "node_modules/(?!(@rescript/core|rescript-bun)/)",
    ],
};
