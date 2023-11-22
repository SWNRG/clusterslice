#!/bin/bash

kubectl label nodes kubew1 \
    edge-net.io/as=University_of_Macedonia__Economic_and_Social_Sciences \
    edge-net.io/asn="12364" \
    edge-net.io/city=Thessaloniki \
    edge-net.io/continent=Europe \
    edge-net.io/country-iso=GR \
    edge-net.io/isp=National_Infrastructures_for_Research_and_Technolo \
    edge-net.io/lat=n40.643900 \
    edge-net.io/lon=e22.935800 \
    edge-net.io/state-iso=B
