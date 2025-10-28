{{/*
Expand the name of the chart.
*/}}
{{- define "gcp-vm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "gcp-vm.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "gcp-vm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "gcp-vm.labels" -}}
helm.sh/chart: {{ include "gcp-vm.chart" . }}
{{ include "gcp-vm.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "gcp-vm.selectorLabels" -}}
app.kubernetes.io/name: {{ include "gcp-vm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "gcp-vm.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "gcp-vm.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
This helper template is used to find the best VM size based on the CPU and Memory requirements.
Note: currently not used.
*/}}
{{- define "findBestVmSize" -}}
{{- $cpu := .cpu -}}
{{- $memory := .memory -}}
{{- $vmSizes := .vmSizes -}}
{{- $defaultVmSize := .defaultVmSize -}}
{{- $cpuThreshold := .cpuThreshold | default 1 -}}
{{- $memoryThreshold := .memoryThreshold | default 2 -}}
{{- $minDiff := 9999 -}}
{{- $bestMatch := $defaultVmSize -}}

{{- range $vmSizes }}
    {{- $cpuDiff := sub (max $cpu .cpu) (min $cpu .cpu) -}}
    {{- $memoryDiff := sub (max $memory .memory) (min $memory .memory) -}}
    
    {{- if and (le $cpuDiff $cpuThreshold) (le $memoryDiff $memoryThreshold) }}
        {{- $totalDiff := add $cpuDiff $memoryDiff -}}
        {{- if le $totalDiff $minDiff }}
            {{- $minDiff = $totalDiff -}}
            {{- $bestMatch = .size -}}
        {{- end }}
    {{- end }}
{{- end }}
{{- $bestMatch -}}
{{- end -}}

{{/*
[GCP]
Helper template to get a GCP zone in the GCP region based on hash of the VM name
The consistency is needed since the function is called in more than one template
*/}}
{{- define "getZone" -}}
{{- $regionZoneMap := index . 0 -}}
{{- $region := trim (index . 1) -}}  {{/* Trim whitespace */}}
{{- $vmName := index . 2 -}}

{{- if hasKey $regionZoneMap $region -}}
    {{- $zones := index $regionZoneMap $region -}}
    {{- if gt (len $zones) 0 -}}
        {{- $hash := sha256sum $vmName -}}
        {{- $hashSlice := trunc 8 $hash -}}
        {{- $hashInt := (mod (atoi $hashSlice) (len $zones)) -}}  {{/* Convert to int and calculate index */}}
        {{- index $zones $hashInt -}}
    {{- else -}}
        {{- fail (printf "No zones available for region %s" $region) -}}
    {{- end -}}
{{- else -}}
    {{- fail (printf "Region %s not found in region zone map" $region) -}}
{{- end -}}
{{- end -}}
