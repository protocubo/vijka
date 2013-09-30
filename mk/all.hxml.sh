#!/bin/bash

rm -f all.hxml
for f in `ls mk/vijka.*.hxml mk/UnitTests.*.hxml`; do
	echo -e "# $f\n" >> all.hxml
	cat $f >> all.hxml
	echo -e "\n--next\n\n\n" >> all.hxml
done
echo -e "-cmd echo Done" >> all.hxml
