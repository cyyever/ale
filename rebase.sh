set -eu
git branch -D cyy || true
git push -d origin cyy || true

branches="auto_cc powershell_formatter textidote error_first encoding pvsstudio"
for branch in $branches; do
  echo "rebase ${branch}"
  git checkout ${branch}
  git rebase up/master
  git push --force
  echo "end rebase ${branch}"
done
git checkout -b cyy
for branch in $branches; do
  echo "rebase ${branch}"
  git rebase ${branch}
  echo "end rebase ${branch}"
done
git push --set-upstream origin cyy
