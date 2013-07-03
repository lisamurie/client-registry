﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using MARC.HI.EHRS.SVC.Messaging.FHIR.Resources;
using MARC.HI.EHRS.CR.Core.ComponentModel;
using MARC.HI.EHRS.SVC.Core.ComponentModel.Components;
using MARC.HI.EHRS.SVC.Core.Services;
using MARC.HI.EHRS.SVC.Messaging.FHIR.DataTypes;
using MARC.Everest.Connectors;
using MARC.HI.EHRS.SVC.Core.DataTypes;
using MARC.HI.EHRS.SVC.Core.ComponentModel;
using MARC.HI.EHRS.CR.Messaging.FHIR.Util;
using MARC.HI.EHRS.SVC.Messaging.FHIR;
using MARC.HI.EHRS.SVC.Messaging.FHIR.Util;
using MARC.HI.EHRS.SVC.Messaging.FHIR.Attributes;

namespace MARC.HI.EHRS.CR.Messaging.FHIR.Processors
{
    /// <summary>
    /// Message processor for patients
    /// </summary>
    [Profile(ProfileId = "pix-fhir")]
    [ResourceProfile(Resource = typeof(Patient), Name = "Client registry patient profile")]
    public class PatientMessageProcessor : MessageProcessorBase, IFhirMessageProcessor
    {
        #region IFhirMessageProcessor Members

        /// <summary>
        /// The name of the resource
        /// </summary>
        public override string ResourceName
        {
            get { return "Patient"; }
        }

        /// <summary>
        /// Gets the type of resource
        /// </summary>
        public override Type ResourceType
        {
            get { return typeof(Patient); }
        }

        /// <summary>
        /// Component type that matches this
        /// </summary>
        public override Type ComponentType
        {
            get { return typeof(Person); }
        }

        /// <summary>
        /// Parse parameters
        /// </summary>
        [SearchParameterProfile(Name = "_id", Type = "token", Description = "Client registry assigned id for the patient (one repetition only)")]
        [SearchParameterProfile(Name = "active", Type = "token", Description = "Whether the patient record is active (one repetition only)")]
        [SearchParameterProfile(Name = "address", Type = "string", Description = "An address in any kind of address part (only supports OR see documentation)")]
        [SearchParameterProfile(Name = "birthdate", Type = "date", Description = "The patient's date of birth (only supports OR)")]
        [SearchParameterProfile(Name = "family", Type = "string", Description = "One of the patient's family names (only supports AND)")]
        [SearchParameterProfile(Name = "given", Type = "string", Description = "One of the patient's given names (only supports AND)")]
        [SearchParameterProfile(Name = "gender", Type = "token", Description = "Gender of the patient (one repetition only)")]
        [SearchParameterProfile(Name = "identifier", Type = "token", Description = "A patient identifier (only supports OR)")]
        [SearchParameterProfile(Name = "provider.identifier", Type = "token", Description = "One of the organizations to which this person is a patient (only supports OR)")]
        public override Util.DataUtil.ClientRegistryFhirQuery ParseQuery(System.Collections.Specialized.NameValueCollection parameters, List<IResultDetail> dtls)
        {
            ITerminologyService termSvc = ApplicationContext.CurrentContext.GetService(typeof(ITerminologyService)) as ITerminologyService;

            Util.DataUtil.ClientRegistryFhirQuery retVal = base.ParseQuery(parameters, dtls);

            var queryFilter = new Person();
            //MARC.HI.EHRS.SVC.Core.DataTypes.AddressSet addressFilter = null;
            MARC.HI.EHRS.SVC.Core.DataTypes.NameSet nameFilter = null;

            for(int i = 0; i < parameters.Count; i++)
                try
                {
                    switch (parameters.GetKey(i))
                    {
                        case "_id":
                            {
                                if (queryFilter.AlternateIdentifiers == null)
                                    queryFilter.AlternateIdentifiers = new List<DomainIdentifier>();

                                if (parameters.GetValues(i).Length > 1)
                                    dtls.Add(new InsufficientRepetitionsResultDetail(ResultDetailType.Warning, "Cannot perform AND on identifier", null));

                                var appDomain = ApplicationContext.ConfigurationService.OidRegistrar.GetOid("CR_CID").Oid;
                                StringBuilder actualIdParm = new StringBuilder();
                                foreach (var itm in parameters.GetValues(i)[0].Split(','))
                                {
                                    var domainId = MessageUtil.IdentifierFromToken(itm);
                                    if (domainId.Domain == null)
                                        domainId.Domain = appDomain;
                                    else if (!domainId.Domain.Equals(appDomain))
                                    {
                                        var dtl = new UnrecognizedPatientDomainResultDetail(ApplicationContext.LocalizationService, domainId.Domain);
                                        dtl.Location = "_id";
                                        dtls.Add(dtl);
                                        continue;
                                    }
                                    queryFilter.AlternateIdentifiers.Add(domainId);
                                    actualIdParm.AppendFormat("{0},", itm);
                                }

                                retVal.ActualParameters.Add("_id", actualIdParm.ToString());
                                break;
                            }
                        case "active":
                            queryFilter.Status = Boolean.Parse(parameters.GetValues(i)[0]) ? StatusType.Active | StatusType.Completed : StatusType.Obsolete | StatusType.Nullified | StatusType.Cancelled | StatusType.Aborted;
                            retVal.ActualParameters.Add("active", (queryFilter.Status == (StatusType.Active | StatusType.Completed)).ToString());
                            break;
                        //case "address.use":
                        //case "address.line":
                        //case "address.city":
                        //case "address.state":
                        //case "address.zip":
                        //case "address.country":
                        //    {
                        //        if (addressFilter == null)
                        //            addressFilter = new SVC.Core.DataTypes.AddressSet();
                        //        string property = parameters.GetKey(i).Substring(parameters.GetKey(i).IndexOf(".") + 1);
                        //        string value = parameters.GetValues(i)[0];

                        //        if(value.Contains(",") || parameters.GetValues(i).Length > 1)
                        //            dtls.Add(new InsufficientRepetitionsResultDetail(ResultDetailType.Warning, "Cannot perform AND or OR on address fields", "address." + property));

                        //        if (property == "use")
                        //        {
                        //            addressFilter.Use = HackishCodeMapping.Lookup(HackishCodeMapping.ADDRESS_USE, value);
                        //            retVal.ActualParameters.Add("address.use", HackishCodeMapping.ReverseLookup(HackishCodeMapping.ADDRESS_USE, addressFilter.Use));
                        //        }
                        //        else
                        //            addressFilter.Parts.Add(new SVC.Core.DataTypes.AddressPart()
                        //            {
                        //                AddressValue = value,
                        //                PartType = HackishCodeMapping.Lookup(HackishCodeMapping.ADDRESS_PART, value)
                        //            });
                        //            retVal.ActualParameters.Add(String.Format("address.{0}", HackishCodeMapping.ReverseLookup(HackishCodeMapping.ADDRESS_PART, addressFilter.Parts.Last().PartType)), value);

                        //        break;
                        //    }
                        case "address": // Address is really messy ... 
                            {
                                queryFilter.Addresses = new List<SVC.Core.DataTypes.AddressSet>();
                                // OR is only supported for this
                                if (parameters.GetValues(i).Length > 1)
                                    dtls.Add(new InsufficientRepetitionsResultDetail(ResultDetailType.Warning, "Cannot perform AND on address", null));


                                var actualAdParm = new StringBuilder();
                                foreach(var ad in parameters.GetValues(i))
                                {
                                    foreach (var adpn in parameters.GetValues(i)[0].Split(','))
                                    {
                                        foreach (var kv in HackishCodeMapping.ADDRESS_PART)
                                            queryFilter.Addresses.Add(new SVC.Core.DataTypes.AddressSet()
                                            {
                                                Use = SVC.Core.DataTypes.AddressSet.AddressSetUse.Search,
                                                Parts = new List<SVC.Core.DataTypes.AddressPart>() {
                                                    new MARC.HI.EHRS.SVC.Core.DataTypes.AddressPart() {
                                                        PartType = kv.Value,
                                                        AddressValue = adpn
                                                    }
                                                }
                                            });
                                        actualAdParm.AppendFormat("{0},", adpn);
                                    }
                                }

                                retVal.ActualParameters.Add("address", actualAdParm.ToString());
                                break;
                            }
                        case "birthdate":
                            {
                                string value = parameters.GetValues(i)[0];
                                if (value.Contains(","))
                                    value = value.Substring(0, value.IndexOf(","));
                                else if (parameters.GetValues(i).Length > 1)
                                    dtls.Add(new InsufficientRepetitionsResultDetail(ResultDetailType.Warning, "Cannot perform AND on birthdate", null));

                                var dValue = new DateOnly() { Value = value };
                                queryFilter.BirthTime = new SVC.Core.DataTypes.TimestampPart()
                                {
                                    Value = dValue.DateValue.Value,
                                    Precision = HackishCodeMapping.ReverseLookup(HackishCodeMapping.DATE_PRECISION, dValue.Precision)
                                };
                                retVal.ActualParameters.Add("birthdate", dValue.XmlValue);
                                break;
                            }
                        case "family":
                            {
                                if (nameFilter == null)
                                    nameFilter = new SVC.Core.DataTypes.NameSet() { Use = SVC.Core.DataTypes.NameSet.NameSetUse.Search };

                                foreach (var nm in parameters.GetValues(i))
                                {
                                    if (nm.Contains(",")) // Cannot do an OR on Name
                                        dtls.Add(new InsufficientRepetitionsResultDetail(ResultDetailType.Warning, "Cannot perform OR on family", null));

                                    nameFilter.Parts.Add(new SVC.Core.DataTypes.NamePart()
                                    {
                                        Type = SVC.Core.DataTypes.NamePart.NamePartType.Family,
                                        Value = parameters.GetValues(i)[0]
                                    });
                                    retVal.ActualParameters.Add("family", nm);
                                }
                                break;
                            }
                        case "given":
                            {

                                if (nameFilter == null)
                                    nameFilter = new SVC.Core.DataTypes.NameSet() { Use = SVC.Core.DataTypes.NameSet.NameSetUse.Search };
                                foreach (var nm in parameters.GetValues(i))
                                {
                                    if (nm.Contains(",")) // Cannot do an OR on Name
                                        dtls.Add(new InsufficientRepetitionsResultDetail(ResultDetailType.Warning, "Cannot perform OR on given", null));
                                    nameFilter.Parts.Add(new SVC.Core.DataTypes.NamePart()
                                    {
                                        Type = SVC.Core.DataTypes.NamePart.NamePartType.Given,
                                        Value = nm
                                    });
                                    retVal.ActualParameters.Add("given", nm);
                                }
                                break;
                            }
                        case "gender":
                            {
                                string value = parameters.GetValues(i)[0].ToUpper();
                                if (value.Contains(",") || parameters.GetValues(i).Length > 1)
                                    dtls.Add(new InsufficientRepetitionsResultDetail(ResultDetailType.Warning, "Cannot perform OR or AND on gender", null));

                                var gCode = MessageUtil.CodeFromToken(value);
                                if (gCode.Code == "UNK") // Null Flavor
                                    retVal.ActualParameters.Add("gender", String.Format("http://hl7.org/fhir/v3/NullFlavor!UNK"));
                                else if (!new List<String>() { "M", "F", "UN" }.Contains(gCode.Code))
                                    dtls.Add(new VocabularyIssueResultDetail(ResultDetailType.Error, String.Format("Cannot find code {0} in administrative gender", gCode.Code), null));

                                else
                                {
                                    queryFilter.GenderCode = gCode.Code;
                                    retVal.ActualParameters.Add("gender", String.Format("http://hl7.org/fhir/v3/AdministrativeGender!{0}", gCode.Code));
                                }
                                break;
                            }
                        case "identifier":
                            {
                                if (parameters.GetValues(i).Length > 1)
                                    dtls.Add(new InsufficientRepetitionsResultDetail(ResultDetailType.Warning, "Cannot perform AND on identifiers", null));

                                if (queryFilter.AlternateIdentifiers == null)
                                    queryFilter.AlternateIdentifiers = new List<SVC.Core.DataTypes.DomainIdentifier>();
                                StringBuilder actualIdParm = new StringBuilder();
                                foreach (var val in parameters.GetValues(i)[0].Split(','))
                                {
                                    var domainId = MessageUtil.IdentifierFromToken(val);
                                    if (String.IsNullOrEmpty(domainId.Domain))
                                    {
                                        dtls.Add(new NotImplementedResultDetail(ResultDetailType.Error, "'identifier' must carry system, cannot perform generic query on identifiers", null, null));
                                        continue;
                                    }
                                    queryFilter.AlternateIdentifiers.Add(domainId);
                                    actualIdParm.AppendFormat("{0},", val);
                                }

                                retVal.ActualParameters.Add("identifier", actualIdParm.ToString()); 
                                break;
                            }
                        case "provider.identifier": // maps to the target domains ? 
                            {

                                foreach (var val in parameters.GetValues(i)[0].Split(','))
                                {
                                    var did = new DomainIdentifier() { Domain = MessageUtil.IdentifierFromToken(val).Domain };
                                    if (String.IsNullOrEmpty(did.Domain))
                                    {
                                        dtls.Add(new NotSupportedChoiceResultDetail(ResultDetailType.Warning, "Provider organization identifier unknown", null));
                                        continue;
                                    }

                                    queryFilter.AlternateIdentifiers.Add(did);
                                    retVal.ActualParameters.Add("provider.identifier", String.Format("{0}!", MessageUtil.TranslateDomain(did.Domain)));
                                }
                                break;

                            }
                        default:
                            if(retVal.ActualParameters.Get(parameters.GetKey(i)) == null)
                                dtls.Add(new NotSupportedChoiceResultDetail(ResultDetailType.Warning, String.Format("{0} is not a supported query parameter", parameters.GetKey(i)), null));
                            break;
                    }
                }
                catch (Exception e)
                {
                    dtls.Add(new ResultDetail(ResultDetailType.Error, string.Format("Unable to process parameter {0} due to error {1}", parameters.Get(i), e.Message), e));
                }

            // Add a name filter?
            if(nameFilter != null)
                queryFilter.Names = new List<SVC.Core.DataTypes.NameSet>() { nameFilter };

            retVal.Filter = queryFilter;

            return retVal;
        }

        /// <summary>
        /// Process resource
        /// </summary>
        public override System.ComponentModel.IComponent ProcessResource(ResourceBase resource, List<IResultDetail> dtls)
        {
            throw new NotImplementedException();
        }

        /// <summary>
        /// Process components
        /// </summary>
        /// TODO: make this more robust
        [ElementProfile(Property = "Link", MaxOccurs = 0, ShortDescription = "This registry only supports links through 'contact' relationships")]
        [ElementProfile(Property = "Animal", MaxOccurs = 0, ShortDescription = "This registry only supports human patients")]
        [ElementProfile(HostType = typeof(Contact), Property = "Organization", MaxOccurs = 0, ShortDescription = "This registry only supports relationships with 'Person' objects")]
        [ElementProfile(HostType = typeof(Demographics), Property = "Photo", MaxOccurs = 0, ShortDescription = "This registry does not support the storage of photographs directly")]
        public override ResourceBase ProcessComponent(System.ComponentModel.IComponent component, List<IResultDetail> dtls)
        {
            // Setup references
            Patient retVal = new Patient();
            Person person = component as Person;

            retVal.Id = person.Id;
            retVal.VersionId = person.VersionId;
            retVal.Active = (person.Status & (StatusType.Active | StatusType.Completed)) != null;

            // Deceased time
            if (person.DeceasedTime != null)
            {
                retVal.DeceasedDate = person.DeceasedTime.Value;
                retVal.DeceasedDate.Precision = HackishCodeMapping.Lookup(HackishCodeMapping.DATE_PRECISION, person.DeceasedTime.Precision);
            }

            // Identifiers
            foreach(var itm in person.AlternateIdentifiers)
                retVal.Identifier.Add(base.ConvertDomainIdentifier(itm));

            // Birth order
            if (person.BirthOrder.HasValue)
                retVal.MultipleBirth = (FhirInt)person.BirthOrder.Value;

            retVal.Details = new Demographics();

            // Names
            if(person.Names != null)
                foreach (var name in person.Names)
                    retVal.Details.Name.Add(base.ConvertNameSet(name));
            // Addresses
            if (person.Addresses != null)
                foreach (var addr in person.Addresses)
                    retVal.Details.Address.AddRange(base.ConvertAddressSet(addr));
            // Telecom
            if (person.TelecomAddresses != null)
                foreach (var tel in person.TelecomAddresses)
                    retVal.Details.Telecom.AddRange(base.ConvertTelecom(tel));
            // Gender
            if (person.GenderCode != null)
                retVal.Details.Gender = new CodeableConcept(new Uri("http://hl7.org/fhir/v3/AdministrativeGender"), person.GenderCode);
            // DOB
            retVal.Details.BirthDate = new Date(person.BirthTime.Value) { Precision = HackishCodeMapping.Lookup(HackishCodeMapping.DATE_PRECISION, person.BirthTime.Precision) };

            // Confidence?
            var confidence = person.FindComponent(HealthServiceRecordSiteRoleType.ComponentOf | HealthServiceRecordSiteRoleType.CommentOn) as QueryParameters;
            if (confidence != null)
                retVal.Extension.Add(ExtensionUtil.CreateConfidenceExtension(confidence));
                        
            return retVal;
        }

        #endregion
    }
}
