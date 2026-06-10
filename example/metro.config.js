const { getDefaultConfig } = require('expo/metro-config');
const path = require('path');

const projectRoot = __dirname;
const workspaceRoot = path.resolve(projectRoot, '..');

const config = getDefaultConfig(projectRoot);

config.watchFolders = [workspaceRoot];

config.resolver.nodeModulesPaths = [
  path.resolve(projectRoot, 'node_modules'),
  path.resolve(workspaceRoot, 'node_modules'),
];

// Parent'taki react/react-native kopyalarını engelle (çift RN = PlatformConstants hatası)
config.resolver.blockList = [
  ...Array.from(config.resolver.blockList ?? []),
  new RegExp(
    `${path.resolve(workspaceRoot, 'node_modules', 'react').replace(/\\/g, '\\\\')}/.*`
  ),
  new RegExp(
    `${path.resolve(workspaceRoot, 'node_modules', 'react-native').replace(/\\/g, '\\\\')}/.*`
  ),
];

config.resolver.extraNodeModules = {
  'raxon-barcode-scanner': workspaceRoot,
};

module.exports = config;
