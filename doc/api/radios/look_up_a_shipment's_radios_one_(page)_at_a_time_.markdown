# Radios API

## Look up a shipment&#39;s radios one (page) at a time 

### GET /shipments/:shipment_id/radios

Each page only returns 1 record. The header `X-Total` will give the total number of radios (pages)

### Parameters

| Name | Description | Required | Scope |
|------|-------------|----------|-------|
| page | String, paganation page number | false |  |

### Request

#### Headers

<pre>Authorization: Bearer myaccesstoken</pre>

#### Route

<pre>GET /shipments/47/radios?page=2</pre>

#### Query Parameters

<pre>page: 2</pre>

### Response

#### Headers

<pre>Content-Type: application/json; charset=utf-8</pre>

#### Status

<pre>200 OK</pre>

#### Body

<pre>[
  {
    "id": 57,
    "frequency": "80.2",
    "pcb_version": null,
    "serial_number": null,
    "assembly_date": null,
    "operator": null,
    "shipment_id": 47,
    "boxed": false,
    "country_code": "US",
    "firmware_version": null,
    "quality_control_status": null
  }
]</pre>
