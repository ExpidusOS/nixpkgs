#!/usr/bin/env python3

import sys
import subprocess
import os
import argparse

def get_repository_version(repository):
  'Returns the Git HEAD for the supplied repository path as a string.'
  if not os.path.exists(repository):
    raise IOError('path does not exist')

  with open(os.path.join(repository, '.git', 'logs', 'HEAD'), 'r') as head:
    return head.read().strip()

def main():
  parser = argparse.ArgumentParser()

  parser.add_argument(
      '--repository',
      action='store',
      help='Path to the Git repository.',
      required=True
  )

  args = parser.parse_args()
  repository = os.path.abspath(args.repository)
  version = get_repository_version(repository)
  print(version.strip())

  return 0


if __name__ == '__main__':
  sys.exit(main())
