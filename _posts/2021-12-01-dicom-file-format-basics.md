---
title: "DICOM File Format Basics"
excerpt: "Introduction to DICOM file format"
date: December 1, 2021
toc: true
toc_label: "Content"
toc_sticky: true
last_modified_at: December 1, 2021
---

{% include image.html
    src="/assets/images/posts/dicom-basics/dicom-basics-header.jpg"
    alt="dicom-basics-header"
    caption="<a href='https://dailyuknews.com/tech/45-million-medical-scans-from-hospitals-all-over-the-world-left-exposed-online-for-anyone-to-view-some-servers-were-laced-with-malware/' target='_blank'>Image Source</a>"
%}

I would like to thank my former colleagues for introducing me to the DICOM world. 
It's been a pleasure working with them and tackling many problems that come up 
when one tries to understand all ins and outs of such a complex standard as DICOM.

> **Disclaimer**: Everything presented here is part of public knowledge and can 
be found in the resource section.

In this post I'll try to present the basics of DICOM in plain language and 
provide resources that helped me along the way. The DICOM Standard can be 
overwhelming at first but with a nice introduction and basics the learning curve 
can be flattened, which is my goal.

I personally know that this post will be of interest to certain people and I'd 
like to encourage them to contribute and share their knowledge.

# Introduction

For some odd reason you stumbled upon the DICOM Standard. Maybe at work, in a 
conversation or somewhere else but you decided to google it and found out that 
it means: Digital Imaging and Communications in Medicine.

On Wikipedia page you've read:

> Digital Imaging and Communications in Medicine (DICOM) is the standard for 
the communication and management of medical imaging information and related 
data. DICOM is most commonly used for storing and transmitting medical images 
enabling the integration of medical imaging devices such as scanners, servers, 
workstations, printers, network hardware, and picture archiving and 
communication systems (PACS) from multiple manufacturers.

And of course:

> The standard includes a file format definition and a network communications 
protocol that uses TCP/IP to communicate between systems.

Now you have a pretty good idea that the DICOM Standard defines communication 
protocol between different medical imaging devices and a file format. 

But how is it structured and how it works?
Since DICOM is enormous, where should you start? 

In my opinion, the best starting point is to understand the file format and how 
it is used to represent medical images among other things. So, let's look at 
some basic building block of DICOM file format.

# DICOM file format

DICOM file can be used to represent many things: Single/Multi frame Images, 
Structured Reports, Encapsulated PDF storage, Videos etc.

For now we will focus only on images.

To open DICOM files you can use: [MicroDicom](https://www.microdicom.com/){:target="_blank"}, 
it's a free DICOM viewer for Windows or if you prefer online viewer with 
some sample files see: [DICOM Library](https://www.dicomlibrary.com/){:target="_blank"}.

When you open a file you'll see something like this:

<a name="microdicom-preview"></a>
{% include image.html
    src="/assets/images/posts/dicom-basics/microdicom-preview.jpg"
    alt="microdicom-preview"
    caption="MicroDicom Preview <a href='https://www.pinterest.com/pin/521010250614116211/' target='_blank'>Source</a>"
%}

At the most basic level you can look at a DICOM file as a file that contains an 
image and information about the image: how, when, and where it's been created, 
who it belongs to, device used for its creation etc, and of course the image 
itself. However, just like any other file format (PDF, Excel, Word ...) it has a 
complex internal structure used for storing that information.

## Structure

DICOM file is comprised of a Header and a Data Set:

{% include image.html
    src="/assets/images/posts/dicom-basics/dicom-file-structure.png"
    alt="dicom-file-structure"
    caption="DICOM File Structure <a href='https://www.sachpazidis.com/dicom-tags-modification/' 
    target='_blank'>Source</a>"
%}

- Header, also known as DICOM File Meta Information, includes a preamble, 
followed by 128 byte File Preamble, followed by 4 byte DICOM prefix, followed 
by the File Meta Elements which include elements such as the TransferSyntaxUID 
(which is every important for understanding the file format).

- Data Set is a collection of Data Elements. 


## DICOM Element

If you look closely at the [MicroDicom preview image](#microdicom-preview) 
from above, you'll see a list on the right hand side. 
That list shows DICOM attributes.

DICOM attribute (or Data Element) is a unit for storing information and it has 
a well predefined tag and purpose defined in the DICOM Standard (we will see 
later different types of tags that are not defined). For example the list can 
contain the following attributes:

Tag         | Tag Description       | Value                     |
----------- | --------------------- | ------------------------- |
(0002,0010) | Transfer Syntax UID   | 1.2.840.10008.1.2.4.91    |
(0008,0008) | Image Type            | ORIGINAL, PRIMARY         |
(0008,0016) | SOP Class UID         | 1.2.840.10008.5.1.4.1.1.2 |
(0008,0060) | Modality              | CT                        |
(0010,0010) | Patient's Name        | VladSiv                   |
(0010,0020) | Patient's ID          | 0123456789                |
(0028,0100) | Bits Allocated        | 16                        |
(0028,0101) | Bits Stored           | 12                        |
...         | ...                   | ...                       |
----------- | --------------------- | ------------------------- |

> If you are interested, you can explore more attributes by browsing: 
[Registry of DICOM Data Elements](https://dicom.nema.org/medical/Dicom/current/output/chtml/part06/chapter_6.html){:target="_blank"}

Attributes are composed of, at least, three fields:

- **Tag** - identifies the element
- **Value Length** (VL) - defines the length of the attribute's value
- **Value Field** (VF) - contains the attribute's data

And for some types of Transfer Syntaxes (we will see later what they are), there 
is another field:

- **Value Representation** (VR) - describes the data type and format of the
attribute's value

Visually we can represent that as:

{% include image.html
    src="/assets/images/posts/dicom-basics/dicom-element.svg"
    alt="dicom-element"
    caption="DICOM Element <a href='https://dicom.nema.org/medical/dicom/current/output/html/figures/PS3.5_7.1-1.svg' target='_blank'>Source</a>"
%}

### Tags

Every DICOM element has a Tag that uniquely indetifies the element and is 
represented as: `(gggg,eeee)`, where `gggg` represents the Group Number and 
`eeee` the Element Number.

Group and Element numbers are 16-bit unsigned integers and are represented in 
hexadecimal notation.

A Group is a collection of elements that are somehow related, 
for example:

| Tag           | Tag Description       |
| ------------- | --------------------- |
| (0010,0010)   | Patient's Name        |
| (0010,0020)   | Patient ID            |
| (0010,0021)   | Issuer of Patient ID  |
| (0010,0022)   | Type of Patient ID    |
| (0010,0030)   | Patient's Birth Date  |
| (0010,0040)   | Patient's Sex         |
| ...           | ...                   |
| ------------- | --------------------- |   


> Actually, a Group belongs to an attribute of an abstract concept called 
**Information Object Definition** (IOD) and the Patient group to
Patient **Module** - I'll explain how it works later.

### Value Length

Depending on VR, VL can be of defined or undefined lenght. If it's defined then 
it's a 16 or 32-bit unsigned integer containing the explicit length of the 
Value Field as the number of bytes that make up the Value.

### Value Field

Represents an even number of bytes containing the Value of the Data Element. 
It's obvious that the data type of the stored Value depends on VR as explained 
above. 

However, VF can contain multiple values and that's defined by 
**Value Multiplicity** (VM). For data elements that are defined in the Standard, each 
element has a defined VM and if it is greater than 1, multiple values are delimited 
within the VF. 

> To see VMs of tags defined in the DICOM Standard, please see: 
[Registry of DICOM Data Elements](https://dicom.nema.org/medical/Dicom/current/output/chtml/part06/chapter_6.html){:target="_blank"}

### Value Representation

VR is really important as it defines how the VF will be interpreted. The most 
important thing to remember is that VR can be:

- Explicit - Is contained in Data Element
- Implicit - Is missing from Data Element

You may be asking now, if it's missing how do we know how to interpret the VF?

Well, it's defined in the Standard, and when you get the Tag `(gggg,eeee)` you 
know what to expect, that's why it's implicit. If something is not right, and 
for example your application cannot parse the data element, then the data 
element is not encoded in accordance with the Standard.

If it's present in the data element. It contains two byte characters which are 
always encoded using upper case letters.

The list of possible VRs is quite extensive and details about encoding, character 
repertoire, and length of value can be found in the Standard: 
[Value Representation](https://dicom.nema.org/medical/dicom/current/output/html/part05.html#sect_6.2){:target="_blank"}

To mention some of them:

| VR    | Name              |
| ----- | ----------------- |
| CS    | Code String       |
| DS    | Decimal String    |
| DT    | Date Time         |
| LO    | Long String       |
| LT    | Long Text         |
| OB    | Other Byte        |
| PN    | Person Name       |
| SH    | Short String      |
| SQ    | Sequence of Items |
| ...   | ...               |
| ----- | ----------------- |

### Public and Private

The DICOM Standard allows private data elements which don't belong to Standard 
Data Elements i.e. are not defined in the Standard. This allows different 
implementations of communication of information. For example, private elements 
can be used by different machine manufacturers to specify element where the 
proprietary data is stored.

However, private data elements have to have the same structure as Standard 
Data Elements i.e. Tag, VL, VF, VR, VM etc.

How do we distinguish between private and public elements? 

It's easy, public elements have an even Group number, while private groups 
have odd numbers.

> Note: Elements with Tags `(0001,xxxx)`, `(0003,xxxx)`, `(0005,xxxx)`, 
`(0007,xxxx)`, and `(FFFF,xxxx)` cannot be used. To learn more about 
implemention of private tags please see: [Private Data Element Tags](https://dicom.nema.org/medical/dicom/current/output/html/part05.html#sect_7.8.1){:target="_blank"}

### Type of elements

DICOM attributes may be required in a Data Set (depending on IOD or a SOP 
class, we will define them later).

Some of the attributes are mandatory, others are mandatory under certain 
conditions and of course, some are completely optional.

There are 5 types:

- **Type 1**: Required data element, it cannot be empty. Absence of a value of 
a Type 1 data element is a protocol violation
- **Type 1C**: Same as Type 1 but is required under certain conditions
- **Type 2**: Required data element, but it can be empty if the value is 
unknown. For example, think of the Patient's name, it is a required element but the 
actual name i.e. value can be unknown at the moment of performing a scan.
- **Type 2C**: Same as Type 2 but is required under certain conditions
- **Type 3**: Optional tags

### Nested Tags

You can define nested tags in a DICOM Data Set, this is done using **Sequence 
of Items** (SQ) VR as mentioned above. This allows you to define a tag that 
has a sequence of items, where each item contains a set of Data Elements.

For example, tag: `(0010,1002)` - _Other Patient IDs Sequence_; can contain many 
items that represent Patient ID Data Set. If you are familiar with JSON 
objects, you can look at it like:

```json
{
    "Other Patient IDs Sequence": [
        {
            "PatientID": "id",
            "Issuer of Patient ID": "issuer",
            "Type of Patient ID": "type",
            "Issuer Of Patient ID Qualifiers Sequence": {
                "Universal Entity ID": "uni",
                "Universal Entity ID Type": "uni_type",
                ...
            }
        },
        {...},
        {...}
    ]
}
```

To be more precise about the structure of these items and nested data set, we 
could depict it:

{% include image.html
    src="/assets/images/posts/dicom-basics/dicom-basics-sq.jpg"
    alt="dicom-sq"
    caption="Sequence structure, <a href='https://www.medicalconnections.co.uk/kb/DICOM-Sequences/' 
    target='_blank'>Source</a>"
%}

If you would like to know more about encoding of nested data sets, please see: 
[Nesting of Data Sets](https://dicom.nema.org/medical/dicom/current/output/html/part05.html#sect_7.5){:target="_blank"}

## Transfer Syntax

We now know that we can have different types of tags and value representations, 
also that they can be implicit or explicit. When dealing with objects in general 
we have to store them somehow and send them to different applications. Basically, 
everyone should know how to read and use the object. To put it more precisely, 
everyone should be able to serialize and deserialize a DICOM object.

Transfer Syntax does exactly that, it tells you how to read a DICOM object. It 
defines three things:

- Explicit/Implicit VR - If VRs are present in a Data Element or not
- Big/Little Endian - Byte ordering, see: [Endianness](https://en.wikipedia.org/wiki/Endianness){:target="_blank"}
- Native/Encapsulated Pixel Data - If pixel data is compressed and what 
compression algorithm is used

However, the Transfer Syntax applies only to the Data Set part of a DICOM file, 
while the File Meta Information has always the same encoding. To 
quote the DICOM Standard:

> Except for the 128 byte preamble and the 4 byte prefix, the File Meta 
Information shall be encoded using the Explicit VR Little Endian Transfer 
Syntax as defined in DICOM PS3.5. The Unknown (UN) Value Representation shall 
not be used in the File Meta Information. 
Ref: [DICOM File Meta Information](https://dicom.nema.org/medical/dicom/current/output/html/part10.html#sect_7.1){:target="_blank"}

So, to read a DICOM file, you have to:

- Skip preamble (Why? See: [Preamble Hack](#preamble-hack)) 
- Confirm that it's indeed a DICOM file, by reading bytes 128-131 which should 
be "DICM" i.e. DICOM prefix (don't rely on extenstions, it could be anything and 
is not specified in the Standard)
- Start parsing all `0002` tags with Explicit VR Little Endian
- Get `(0002,0010)` - TransferSyntaxUID and use it to parse the Data Set

Transfer Syntaxes are defines with UIDs:

| Transfer Syntax Name                                                                                  | Transfer Syntax UID           |
| ----------------------------------------------------------------------------------------------------- | ----------------------------- |
| Implicit VR Endian: Default <br>Transfer Syntax for DICOM                                             | 1.2.840.10008.1.2             |
| Explicit VR Little Endian                                                                             | 1.2.840.10008.1.2.1           |
| Deflated Explicit VR Little Endian                                                                    | 1.2.840.10008.1.2.1.99        |
| JPEG Baseline (Process 1): <br>Default Transfer Syntax for Lossy JPEG <br> 8-bit Image Compression    | 1.2.840.10008.1.2.4.50        |
| JPEG-LS Lossless Image Compression                                                                    | 1.2.840.10008.1.2.4.80        |
| ...                                                                                                   | ...                           |

To get the full list of available Transfer Syntax UIDs, please see: 
[Registry of DICOM Unique Identifiers](https://dicom.nema.org/medical/dicom/current/output/chtml/part06/chapter_A.html){:target="_blank"}

## SOP Class

When it comes to information objects in the DICOM Standard, there is a lot of 
abstract definitions, and I just mentioned some of them like _Information 
Object Definition_ (IOD) and _Module_. 

These topic go beyond the basics of the file format but I'll try to give you 
some really rough guidelines on how it works.

If you are familiar with _Object Oriented Programming_ (OOP) you already know 
that we try to model information in object-oriented abstract data models that 
are used to specify information about the real world objects. In DICOM this 
class is represented as IOD. We can use this class as a template and 
instantiate it with attributes and that gives us a particular Data Set.

Attributes of an IOD describe a property of a real world object and are 
grouped into _Information Entities_ or _Modules_, depending if IOD is 
_Normalized_ or _Composite_.

If you are new to DICOM Standard, you may be asking: What in hell are you 
talking about?  
And I get your point, I like thinking about abstract concepts 
but to really grasp them, they need to be introduced in an undestandable way 
that showcases a real world application.

If you open: [Dicom Standard Browser](https://dicom.innolitics.com/ciods){:target="_blank"}. 
You'll see a list of Composite IODs (CIOD), and there are many of them, such as:
CR Image, CT Image, MR Image, US Image, Encapsulated PDF, etc. When you open 
one of them you'll see Modules, which can be _Mandatory_ (M) or _User Optional_ 
(U). These CIOD actually represent a template which is instantiated from an 
abstact class, which we mentioned. 

All DICOM objects have to include a SOP Common Module, likewise if DICOM 
object represents an image, it should include an Image Module. Other main modules 
are: Patient, Study and Series. Additionally, there are specific modules, if 
we define a DICOM object as a CR Image, we must include a CR Image Module and so on...

**Service-Object Pair Class** (SOP Class) - contains the rules and semantics 
that may restrict the use of the service in the **DICOM Message Service Element** 
(DIMSE) Service Group and/or the attributes of the IOD. This basically means that 
by defining a SOP Class of a DICOM object it specifies the mandatory and 
optional modules of an IOD.

> DIMSE is connected to the part of DICOM Standard that deals with the protocol. 
This is not in the scope of this basic introduction, but if you are interested 
check out: [Dicom Part 7 - Message Exchange](https://dicom.nema.org/medical/dicom/current/output/html/part07.html){:target="_blank"}

SOP Class is defined by SOPClassUID and is always present in a DICOM file in the 
(0008,0016) Data Element. Let's look at some examples:

| SOP name                                  | SOPClassUID                       |
| ----------------------------------------- | --------------------------------- |
| CR Image Storage                          | 1.2.840.10008.5.1.4.1.1.1         |
| CT Image Storage                          | 1.2.840.10008.5.1.4.1.1.2         |
| NM Image Storage                          | 1.2.840.10008.5.1.4.1.1.20        |
| MR Image Storage                          | 1.2.840.10008.5.1.4.1.1.4         |
| Encapsulated PDF Storage                  | 1.2.840.10008.5.1.4.1.1.104.1     |
| Ultrasound Image Storage                  | 1.2.840.10008.5.1.4.1.1.6.1       |
| Video Photographic Image Storage          | 1.2.840.10008.5.1.4.1.1.77.1.4.1  |
| ...                                       | ...                               |

If you are interested in more SOP Class UIDs, please see: 
[Registry of DICOM Unique Identifiers](https://dicom.nema.org/medical/dicom/current/output/chtml/part06/chapter_A.html){:target="_blank"}

Now that we understand the SOP Class, it's important to understand that when 
we create a DICOM file, this file is an instance of the SOP Class. That's why 
we have a Data Element: **SOPInstanceUID** which is globally unique in a DICOM 
file. 

Of course, there are other instances, for example: **StudyInstanceUID** - 
uniquely identifies a study, which can contain many series that are identified 
using **SeriesInstanceUID** and so on...

## Preamble Hack

In 2019, a new hack surfaced and it used DICOM files to enable malware to 
infect patient data. It used the Preamble to insert itself into DICOM files and 
exploit flaws in the design of DICOM.

We know that the Preamble is a part of the Header and that it represents a 128-byte 
section. The purpose of this section is to allow applications to use it for 
specific implementations. For example, it could be used to contain information 
enabling a multi-media applications to randomly access images stored in a DICOM 
Data Set or any other specific implementation.

The important thing here is that the DICOM Standard does not require any 
structure and does not impose any requirements on the data inserted into the 
Preamble. Basically we can insert whatever we want. This allows hackers to 
masquerade an executable file as a DICOM image which will trigger an execution 
of the malware.

If you'd like to find out more about this hack, please read: 
[HIPAA-Protected Malware? Exploiting DICOM Flaw to Embed Malware in CT/MRI Imagery](https://researchcylera.wpcomstaging.com/2019/04/16/pe-dicom-medical-malware/){:target="_blank"}

# Final Words

If you are just starting out with the DICOM Standard it can be daunting when
you look at the 
[DICOM Standard](https://www.dicomstandard.org/current){:target="_blank"}, 
22 parts where, for example, part 3 has 1802 pages in PDF format. 
Just skimming through the whole Standard can take a while :D

The aim of this article is to introduce the basic concepts, related to the 
file format, in a clear and concise manner. Grasping the basics 
will give you a good starting point for exploring the whole Standard.

I hope that this article gets you interested in the DICOM world and 
encourages you to dive deeper and research referenced material.

If you have any questions or suggestions, please reach out, I'm always 
available.

# Resources

- [DICOM Standard](https://www.dicomstandard.org/current){:target="_blank"} - Online DICOM 
Standard, Current Edition
- [DICOM Standard Browser](https://dicom.innolitics.com/ciods){:target="_blank"} - Standalone 
website that offers quick and really pleasent overview of DICOM attributes
- [DICOM is Easy](https://dicomiseasy.blogspot.com/){:target="_blank"} - Great blog about 
sofware programming for medical applications
- DICOM sample files:
  - [RuboMedical](https://www.rubomedical.com/dicom_files/){:target="_blank"}
  - [Osirix Dicom Viewer](https://www.osirix-viewer.com/resources/dicom-image-library/){:target="_blank"}
