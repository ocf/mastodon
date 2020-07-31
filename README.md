# Mastodon @ OCF

[![Build Status](https://jenkins.ocf.berkeley.edu/buildStatus/icon?job=ocf/mastodon/master)](https://jenkins.ocf.berkeley.edu/job/ocf/job/mastodon/job/master)

Avaliable at <https://mastodon.ocf.berkeley.edu>.


## Updating to new version of Mastodon

Mastodon tracks releases on their [GitHub Releases
page](https://github.com/tootsuite/mastodon/releases). When there is a new
release, we upgrade by doing the following.

1. Bump the version tag of the Mastodon repository that is checked out in the
   Makefile.

2. Update the patchset. To do this:
   - Clone the mastodon repository to some subdirectory.
   - Check out the release tag.
   - Run `git am ../patches/*` to apply the current patches as commits.
   - Resolve any conflicts, if they occur.
   - At this point, `git log` should show the tagged commit and then one commit
     for each patch.
   - Run `git format-patch <tag> -o ../patches`, where `<tag>` is the release
     tag, to write out the commits since `<tag>` as patch files.

3. Roll out the changes. Don't forget to follow any instructions specified on
   the releases page. If you need to run any commands (e.g. database migrations
   or other jobs), it's usualy easiest to just exec into a container running in
   Kubernetes.
