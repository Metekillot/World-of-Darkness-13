#!/usr/bin/env node
/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import fs from 'fs';
import https from 'https';
import { env } from 'process';

// process.env.NODE_OPTIONS = '--openssl-legacy-provider';
import { resolve as resolvePath } from 'path';
import Juke from './juke/index.js';
import { DreamMaker } from './lib/byond.js';
import { yarn } from './lib/yarn.js';

// Define TGS_MODE as a Juke.Parameter
const TGS_MODE = process.env.CBT_BUILD_MODE === 'TGS';

Juke.chdir('../..', import.meta.url);
Juke.setup({ file: import.meta.url }).then((code) => {
  // We're using the currently available quirk in Juke Build, which
  // prevents it from exiting on Windows, to wait on errors.
  if (code !== 0 && process.argv.includes('--wait-on-error')) {
    Juke.logger.error('Please inspect the error and close the window.');
  return;
  }

  if (TGS_MODE) {
    // workaround for ESBuild process lingering
    // Once https://github.com/privatenumber/esbuild-loader/pull/354 is merged and updated to, this can be removed
    setTimeout(() => process.exit(code), 10000);
  }
  else {
    process.exit(code);
}
});
const DME_NAME = 'tgstation';

export const CiParameter = new Juke.Parameter({ type: 'boolean' });

// Stores the contents of dependencies.sh as a key value pair
// Best way I could figure to get ahold of this stuff
const dependencies = fs.readFileSync('dependencies.sh', 'utf8')
  .split("\n")
  .map((statement) => statement.replace("export", "").trim())
  .filter((value) => !(value == "" || value.startsWith("#")))
  .map((statement) => statement.split("="))
  .reduce((acc, kv_pair) => {
    acc[kv_pair[0]] = kv_pair[1];
    return acc
}, {})

export const YarnTarget = new Juke.Target({
  parameters: [CiParameter],
  inputs: [
    'tgui/.yarn/+(cache|releases|plugins|sdks)/**/*',
    'tgui/**/package.json',
    'tgui/yarn.lock',
  ],
  outputs: [
    'tgui/.yarn/install-target',
  ],
  executes: ({ get }) => yarn('install', get(CiParameter) && '--immutable'),
});


export const TguiTarget = new Juke.Target({
  dependsOn: [YarnTarget],
  inputs: [
    'tgui/.yarn/releases/*',
    'tgui/yarn.lock',
    'tgui/webpack.config.js',
    'tgui/**/package.json',
    'tgui/packages/**/*.js',
    'tgui/packages/**/*.jsx'
  ],
  outputs: [
    'tgui/public/tgui.bundle.css',
    'tgui/public/tgui.bundle.js',
    'tgui/public/tgui-common.bundle.js',
    'tgui/public/tgui-panel.bundle.css',
    'tgui/public/tgui-panel.bundle.js',
    'code/modules/tgui/USE_BUILD_BAT_INSTEAD_OF_DREAM_MAKER.dm'
  ],
  executes: () => yarn('tgui:build'),
});

// DM target
export const DmTarget = new Juke.Target({
  name: 'dm',
  dependsOn: [TguiTarget],
  inputs: [
    '_maps/map_files/generic/**',
    'maps/**/*.dm',
    'code/**',
    'html/**',
    'icons/**',
    'interface/**',
    'sound/**',
    `${DME_NAME}.dme`,
    'tgui/public/tgui.html',
    'tgui/public/*.bundle.*',
    'tgui/public/*.chunk.*',
  ],
  outputs: ({ get }) => {
    return [
      `${DME_NAME}.dmb`,
      `${DME_NAME}.rsc`,
    ]
  },
  executes: async ({ get }) => {
    await DreamMaker(`${DME_NAME}.dme`, {
      warningsAsErrors: false,
      defines: [],
    });
  }
});

export const BuildTarget = new Juke.Target({
  dependsOn: [TguiTarget, DmTarget]
});


// Main execution function
export default TGS_MODE ? TguiTarget : BuildTarget;
