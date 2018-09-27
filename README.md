# Freshcom API

Freshcom API is undergoing some architectural changes. It will soon to be seperated into two different
repos. **freshcom** and **freshcom_web**.

The freshcom repo will no longer contain any web related stuff and will not depend on phoenix anymore.

This is so that backend developer can extend the feature of freshcom much easily and
developers that want to build their own web layer can have choice of not including
the default web layer.

A sneak peak of what will soon be available is in this draft of [Getting Started Guide](https://github.com/freshcom/freshcom-api/wiki/Getting-Started-(Draft))

The new repo freshcom_web will contain only the web layer and depends on freshcom.

The Web API will not change and the docs in [https://docs.freshcom.io/](https://docs.freshcom.io/) and [freshcom-api-reference](https://github.com/freshcom/freshcom-api-reference)
will stay as is and and serve as a reference to what will be available in the beta version. However development for the [Freshcom Dashboard](https://github.com/freshcom/freshcom-dashboard)
will be slowed down for a bit.
