---
title: 'COSE Header parameter for RFC 3161 Time-Stamp Tokens'
abbrev: TST Header
docname: draft-birkholz-cose-tsa-tst-header-parameter-latest
stand_alone: true
ipr: trust200902
area: Security
wg: TBD
kw: Internet-Draft
cat: std
pi:
  toc: yes
  sortrefs: yes
  symrefs: yes

author:
- ins: H. Birkholz
  name: Henk Birkholz
  org: Fraunhofer SIT
  abbrev: Fraunhofer SIT
  email: henk.birkholz@sit.fraunhofer.de
  street: Rheinstrasse 75
  code: '64295'
  city: Darmstadt
  country: Germany
- ins: M. Riechert
  name: Maik Riechert
  organization: Microsoft
  email: Maik.Riechert@microsoft.com
  country: UK

normative:
  STD70:
    =: RFC5652
    -: CMS
  RFC3161: TSA
  STD96:
    =: RFC9052
    -: COSE

informative:
  RFC9338: countersign

--- abstract

RFC 3161 provides a method to time-stamp a message digest to prove that it was created before a given time. This document defines how signatures of CBOR Signing And Encrypted (COSE) message structures can be time-stamped using RFC 3161 along with the needed header parameter to carry the corresponding time-stamp.

--- middle

# Introduction

Useful new COSE {{-COSE}} header member that is the TST output of RFC 3161.

## Requirements Notation

{::boilerplate bcp14-tagged}

{: #mybody}

# RFC 3161 Time-Stamp Tokens COSE Header Parameter

The use of RFC 3161 Time-Stamp Tokens, often in combination with X.509 certificates, allows for an existing trust infrastructure to be used with COSE.

The new COSE header parameter for carrying time-stamp tokens is defined as:

* Name: RFC 3161 time-stamp tokens
* Label: TBD
* Value Type: bstr / [2*bstr]
* Value Registry: none
* Description: One or more RFC 3161 time-stamp tokens.
* Reference: TBD

The content of the byte string are the bytes of the DER-encoded RFC 3161 TimeStampToken structure. This matches the content of the equivalent header attribute defined in {{-TSA}} for Cryptographic Message Syntax (CMS, see {{-CMS}}) envelopes.

This header parameter allows for a single time-stamp token or multiple time-stamp tokens to be carried in the message. If a single time-stamp token is conveyed, it is placed in a CBOR byte string. If multiple time-stamp tokens are conveyed, a CBOR array of byte strings is used, with each time-stamp token being in its own byte string.

Given that time-stamp tokens in this context are similar to a countersignature {{-countersign}}, the header parameter can be included in the unprotected header of a COSE envelope.

When sending a request to an RFC 3161 Time Stamping Authority (TSA, see {{-TSA}}) to obtain a time-stamp token, then the so-called message imprint ({{Section 2.4 of -TSA}}) of the request MUST be the hash of the bytes within the byte string of the signature field of the COSE structure to be time-stamped. The hash algorithm does not have to match the algorithm used for signing the COSE message.

RFC 3161 time-stamp tokens use CMS as signature envelope format. {{-CMS}} illustrates details of signature verification and {{-TSA}} details specific to time-stamp token validation. The payload of the signed time-stamp token is a TSTInfo structure as defined in {{-TSA}} and contains the message imprint that was sent to the TSA. As part of validation, the message imprint MUST be matched to the hash of the bytes within the byte string of the signature field of the time-stamped COSE structure. The hash algorithm is contained in the message imprint structure, together with the hash itself.

Appendix B of RFC 3161 provides an example of how time-stamp tokens can be used during signature verification of a time-stamped message when using X.509 certificates.

# Privacy Considerations

TBD

# Security Considerations

TBD

Similar security considerations as described in RFC 3161 apply.

# IANA Considerations

TBD

IANA is requested to register the new COSE Header parameter described in section TBD in the "COSE Header Parameters" registry.

--- back

