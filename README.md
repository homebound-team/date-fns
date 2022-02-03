<p align="center">
  <a href="https://date-fns.org/">
    <img alt="date-fns" title="date-fns" src="https://raw.githubusercontent.com/date-fns/date-fns/master/docs/logotype.svg" width="300" />
  </a>
</p>

<p align="center">
  <b>date-fns</b> provides the most comprehensive, yet simple and consistent toolset
  <br>
  for manipulating <b>JavaScript dates</b> in <b>a browser</b> & <b>Node.js</b>.</b>
</p>

<div align="center">

[📖&nbsp; Documentation](https://date-fns.org/docs/Getting-Started/)&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;[🧑‍💻&nbsp; JavaScript Jobs](https://jobs.date-fns.org/)

</div>

<hr>

# It's like [Lodash](https://lodash.com) for dates

- It has [**200+ functions** for all occasions](https://date-fns.org/docs/Getting-Started/).
- **Modular**: Pick what you need. Works with webpack, Browserify, or Rollup and also supports tree-shaking.
- **Native dates**: Uses existing native type. It doesn't extend core objects for safety's sake.
- **Immutable & Pure**: Built using pure functions and always returns a new date instance.
- **TypeScript & Flow**: Supports both Flow and TypeScript
- **I18n**: Dozens of locales. Include only what you need.
- [and many more benefits](https://date-fns.org/)

```js
import { compareAsc, format } from 'date-fns'

format(new Date(2014, 1, 11), 'yyyy-MM-dd')
//=> '2014-02-11'

const dates = [
  new Date(1995, 6, 2),
  new Date(1987, 1, 11),
  new Date(1989, 6, 10),
]
dates.sort(compareAsc)
//=> [
//   Wed Feb 11 1987 00:00:00,
//   Mon Jul 10 1989 00:00:00,
//   Sun Jul 02 1995 00:00:00
// ]
```

The library is available as an [npm package](https://www.npmjs.com/package/date-fns).
To install the package run:

```bash
npm install date-fns --save
# or with yarn
yarn add date-fns
```

## Docs

[See date-fns.org](https://date-fns.org/) for more details, API,
and other docs.

<br />
<!-- END OF README-JOB SECTION -->

## Homebound Fork

This is Homebound's fork of `date-fns`. We forked this repository to extend the functionality of the `businessDays`
functions. Our plan is to PR these improvements back to the mainstream project. However, in the meantime, we have
logic to publish a `.patch` file to layer this functionality on top of the upstream `date-fns` package via the
[`patch-package` project](https://github.com/ds300/patch-package).

### Our Branch

Currently, our code changes live on the [`improved-business-days`](https://github.com/homebound-team/date-fns/tree/improved-business-days)
branch on our fork. The intention with this branch is that it's well-tested and will be PR'ed against the upstream
project.

This branch is tested using the same GitHub actions that run on the upstream project. When you push to this branch, it
does not automatically trigger a new patch publish (see [below](#publishing-the-patch-package) for how to do that).

### Publishing the Patch Package

There are two distinct cases you might want to trigger a new package publish:

1. If you've made changes on the `improved-business-days` branch and want to release them.
1. If a new version of `date-fns` is released upstream.

In either case, you trigger a release by running the [workflow in CircleCI](https://app.circleci.com/pipelines/github/homebound-team/date-fns?branch=homebound-patch-publish&filter=all). Just pick the last workflow run and click the "Rerun workflow from the start" button.

![](https://imgur.com/XFnUtNc)

The release process pulls the latest release tag, merges the `improved-business-days` branch and builds the TypeScript
code. Then, it runs the `patch-package` process to produce a `.patch` file representing the changes.

We publish the private NPM package, `@homebound/date-fns-patch` package for convenience. The versioning convention is
`<upstream-version>-rc.<i>`. For instance, `2.28.0-rc.1` is the first patch we built against the upstream 2.28.0 version.
Because we might publish several revisions against the same upstream version, we simply increment the `-rc.<i>` tag each
time we release. For example, the third publish of the branch against the upstream 2.28.0 version will create
`@homebound/date-fns-patch@2.28.0-rc.3`.

### Using `@homebound/date-fns-patch`

1. You need to have `patch-package` set up in the consuming project. Setup instructions
  [are found in `patch-package`](https://github.com/ds300/patch-package) README.
1. Install the `@homebound/date-fns-patch` NPM package via `npm install --save-dev @homebound/date-fns-patch`.

When you install the package, you'll see a `date-fns` patch appear in the `patches` directory:

```console
> ls -al patches
total 4
-rw-r--r-- 1 blimmer wheel 1213 Feb  2 17:54 date-fns+2.28.0.patch
```

Now `patch-package` will automatically apply this patch, and you can use the new methods directly in your project.

### Troubleshooting

If you run into any problems with this process, please reach out to [Ben Limmer](https://benlimmer.com/freelance) in
Slack.

## License

[MIT © Sasha Koss](https://kossnocorp.mit-license.org/)
