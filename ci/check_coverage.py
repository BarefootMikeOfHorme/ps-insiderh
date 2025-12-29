#!/usr/bin/env python3
import argparse
import xml.etree.ElementTree as ET
import sys

parser = argparse.ArgumentParser()
parser.add_argument('--min', type=int, default=60, help='Minimum total coverage percentage')
parser.add_argument('--report', type=str, default='coverage.xml', help='Path to coverage XML report')
args = parser.parse_args()

try:
    tree = ET.parse(args.report)
except Exception as e:
    print(f'Could not read coverage report: {e}')
    sys.exit(1)

root = tree.getroot()
metrics = root.find('packages') or root.find('packages')
# Fallback: find totals in 'coverage' attributes
coverage_attr = root.get('line-rate')
if coverage_attr is not None:
    total = float(coverage_attr) * 100
else:
    total = None
    for package in root.findall('.//package'):
        cov = package.get('line-rate')
        if cov is not None:
            # Coarse aggregation: take average
            total = (total or 0) + float(cov) * 100
    if total is not None:
        total = total / max(1, len(root.findall('.//package')))

if total is None:
    print('Could not determine total coverage from report')
    sys.exit(1)

print(f'Total coverage: {total:.2f}% (threshold {args.min}%)')
if total < args.min:
    print('Coverage threshold not met')
    sys.exit(1)

print('Coverage threshold met')
sys.exit(0)