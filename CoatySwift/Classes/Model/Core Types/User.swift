//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  User.swift
//  CoatySwift
//
//

import Foundation

/// Object model representing users as defined by the SCIM 2 standard
/// according to RFC7643.
///
/// Note that the SCIM `userName` property is represented in the
/// `name` property of the base CoatyObject type.
open class User: CoatyObject {
    
    // MARK: - Class registration.
    
    override open class var objectType: String {
        return register(objectType: CoreType.User.objectType, with: self)
    }
    
    // MARK: - Initializer.
    
    /// Default initializer for a `User` object.
    ///
    /// - NOTE: In order to populate all optional properties, please just set them manually without
    /// after initializing the object.
    public init(name: String,
                names: ScimUserNames,
                objectType: String = User.objectType,
                objectId: CoatyUUID = .init()) {
        
        self.names = names
        super.init(coreType: .User, objectType: objectType, objectId: objectId, name: name)
    }
    
    // MARK: - Codable methods.
    
    enum UserCodingKeys: String, CodingKey, CaseIterable {
        case names
        case displayName
        case nickName
        case title
        case userType
        case preferredLanguage
        case locale
        case timezone
        case active
        case phoneNumbers
        case password
        case emails
        case ims
        case photos
        case addresses
        case groups
        case entitlements
        case roles
        case x509Certificates
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: UserCodingKeys.self)
        self.names = try container.decode(ScimUserNames.self, forKey: .names)
        self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        self.nickName = try container.decodeIfPresent(String.self, forKey: .nickName)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.userType = try container.decodeIfPresent(String.self, forKey: .userType)
        self.preferredLanguage = try container.decodeIfPresent(String.self, forKey: .preferredLanguage)
        self.locale = try container.decodeIfPresent(String.self, forKey: .locale)
        self.timezone = try container.decodeIfPresent(String.self, forKey: .timezone)
        self.active = try container.decodeIfPresent(Bool.self, forKey: .active)
        self.password = try container.decodeIfPresent(String.self, forKey: .password)
        self.emails = try container.decodeIfPresent([ScimMultiValuedAttribute].self, forKey: .emails)
        self.phoneNumbers = try container.decodeIfPresent([ScimMultiValuedAttribute].self, forKey: .phoneNumbers)
        self.ims = try container.decodeIfPresent([ScimMultiValuedAttribute].self, forKey: .ims)
        self.photos = try container.decodeIfPresent([ScimMultiValuedAttribute].self, forKey: .photos)
        self.addresses = try container.decodeIfPresent([ScimAddress].self, forKey: .addresses)
        self.groups = try container.decodeIfPresent([ScimMultiValuedAttribute].self, forKey: .groups)
        self.entitlements = try container.decodeIfPresent(AnyCodable.self, forKey: .entitlements)
        self.roles = try container.decodeIfPresent([String].self, forKey: .roles)
        self.x509Certificates = try container.decodeIfPresent([String].self, forKey: .x509Certificates)
        
        CoatyObject.addCoreTypeKeys(decoder: decoder, coreTypeKeys: UserCodingKeys.self)
        try super.init(from: decoder)
    }
    
    open override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: UserCodingKeys.self)
        try container.encodeIfPresent(names, forKey: .names)
        try container.encodeIfPresent(displayName, forKey: .displayName)
        try container.encodeIfPresent(nickName, forKey: .displayName)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(userType, forKey: .title)
        try container.encodeIfPresent(preferredLanguage, forKey: .preferredLanguage)
        try container.encodeIfPresent(locale, forKey: .preferredLanguage)
        try container.encodeIfPresent(timezone, forKey: .timezone)
        try container.encodeIfPresent(active, forKey: .timezone)
        try container.encodeIfPresent(phoneNumbers, forKey: .phoneNumbers)
        try container.encodeIfPresent(password, forKey: .phoneNumbers)
        try container.encodeIfPresent(emails, forKey: .emails)
        try container.encodeIfPresent(ims, forKey: .emails)
        try container.encodeIfPresent(photos, forKey: .photos)
        try container.encodeIfPresent(addresses, forKey: .addresses)
        try container.encodeIfPresent(groups, forKey: .groups)
        try container.encodeIfPresent(entitlements, forKey: .groups)
        try container.encodeIfPresent(roles, forKey: .roles)
        try container.encodeIfPresent(x509Certificates, forKey: .roles)
    }
    
    // MARK: Attributes.
    
    /// SCIM userName property: A service provider's unique identifier for the user, typically
    /// used by the user to directly authenticate to the service provider.
    /// Often displayed to the user as their unique identifier within the
    /// system (as opposed to "id" or "externalId", which are generally
    /// opaque and not user-friendly identifiers).  Each User MUST include
    /// a non-empty userName value.  This identifier MUST be unique across
    /// the service provider's entire set of Users.  This attribute is
    /// REQUIRED and is case insensitive.
    override public var name: String {
        get {
            return super.name
        }
        set(value) {
            super.name = value
        }
    }
    
    /// The components of the SCIM user's name.
    /// Service providers MAY return
    /// just the full name as a single string in the formatted
    /// sub-attribute, or they MAY return just the individual component
    /// attributes using the other sub-attributes, or they MAY return
    /// both. If both variants are returned, they SHOULD be describing
    /// the same name, with the formatted name indicating how the
    /// component attributes should be combined.
    public var names: ScimUserNames
    
    /// The name of the user, suitable for display to end-users.Each
    /// user returned MAY include a non- empty displayName value.The name
    /// SHOULD be the full name of the User being described, if known
    /// (e.g., "Babs Jensen" or "Ms. Barbara J Jensen, III") but MAY be a
    /// username or handle, if that is all that is available (e.g.,
    /// "bjensen").The value provided SHOULD be the primary textual
    /// label by which this User is normally displayed by the service
    /// provider when presenting it to end- users.
    public var displayName: String?
    
    /// The casual way to address the user in real life, e.g., "Bob" or
    /// "Bobby" instead of "Robert".This attribute SHOULD NOT be used to
    /// represent a User's username (e.g., bjensen or mpepperidge).
    public var nickName: String?
    
    /// The user's title, such as "Vice President".
    public var title: String?
    
    /// Used to identify the relationship between the organization and the
    /// user. Typical values used might be "Contractor", "Employee",
    /// "Intern", "Temp", "External", and "Unknown", but any value may be
    /// used.
    public var userType: String?
    
    /// Indicates the user's preferred written or spoken languages and is
    /// generally used for selecting a localized user interface.The
    /// value indicates the set of natural languages that are preferred.
    /// The format of the value is the same as the HTTP Accept- Language
    /// header field (not including "Accept-Language:") and is specified
    /// in Section 5.3.5 of [RFC7231].The intent of this value is to
    /// enable cloud applications to perform matching of language tags
    /// [RFC4647] to the user's language preferences, regardless of what
    /// may be indicated by a user agent (which might be shared), or in an
    /// interaction that does not involve a user (such as in a delegated
    /// OAuth 2.0 [RFC6749] style interaction) where normal HTTP
    /// Accept - Language header negotiation cannot take place.
    public var preferredLanguage: String?
    
    /// Used to indicate the User's default location for purposes of
    /// localizing such items as currency, date time format, or numerical
    /// representations.A valid value is a language tag as defined in
    /// [RFC5646].Computer languages are explicitly excluded.
    ///
    /// A language tag is a sequence of one or more case-insensitive
    /// sub - tags, each separated by a hyphen character ("-", %x2D).For
    /// backward compatibility, servers MAY accept tags separated by an
    /// underscore character ("_", %x5F).In most cases, a language tag
    /// consists of a primary language sub- tag that identifies a broad
    /// family of related languages (e.g., "en" = English) and that is
    /// optionally followed by a series of sub- tags that refine or narrow
    /// that language's range (e.g., "en-CA" = the variety of English as
    /// communicated in Canada).  Whitespace is not allowed within a
    /// language tag.Example tags include:
    /// fr, en - US, es - 419, az - Arab, x - pig - latin, man - Nkoo - GN
    /// See[RFC5646] for further information.
    public var locale: String?
    
    /// The User's time zone, in IANA Time Zone database format [RFC6557],
    /// also known as the "Olson" time zone database format [Olson - TZ]
    /// (e.g., "America/Los_Angeles").
    public var timezone: String?
    
    /// A Boolean value indicating the user's administrative status. The
    /// definitive meaning of this attribute is determined by the service
    /// provider.  As a typical example, a value of true implies that the
    /// user is able to log in, while a value of false implies that the
    /// user's account has been suspended.
    public var active: Bool?
    
    /// This attribute is intended to be used as a means to set, replace,
    /// or compare (i.e., filter for equality) a password.  The cleartext
    /// value or the hashed value of a password SHALL NOT be returnable by
    /// a service provider.  If a service provider holds the value
    /// locally, the value SHOULD be hashed.
    public var password: String?
    
    /// Email addresses for the User. The value SHOULD be specified
    /// according to [RFC5321]. Service providers SHOULD canonicalize the
    /// value according to [RFC5321], e.g., "bjensen@example.com" instead
    /// of "bjensen@EXAMPLE.COM".The "display" sub-attribute MAY be used
    /// to return the canonicalized representation of the email value.
    /// The "type" sub-attribute is used to provide a classification
    /// meaningful to the (human) user. The user interface should
    /// encourage the use of basic values of "work", "home", and "other"
    /// and MAY allow additional type values to be used at the discretion
    /// of SCIM clients.
    public var emails: [ScimMultiValuedAttribute]?
    
    /// Phone numbers for the user. The value SHOULD be specified
    /// according to the format defined in [RFC3966], e.g.,
    /// 'tel:+1-201-555-0123'.  Service providers SHOULD canonicalize the
    /// value according to [RFC3966] format, when appropriate.  The
    /// "display" sub-attribute MAY be used to return the canonicalized
    /// representation of the phone number value.  The sub-attribute
    /// "type" often has typical values of "work", "home", "mobile",
    /// "fax", "pager", and "other" and MAY allow more types to be defined
    /// by the SCIM clients.
    public var phoneNumbers: [ScimMultiValuedAttribute]?
    
    /// Instant messaging address for the user.  No official
    /// canonicalization rules exist for all instant messaging addresses,
    /// but service providers SHOULD, when appropriate, remove all
    /// whitespace and convert the address to lowercase.  The "type"
    /// sub-attribute SHOULD take one of the following values: "aim",
    /// "gtalk", "icq", "xmpp", "msn", "skype", "qq", "yahoo", or "other"
    /// (representing currently popular IM services at the time of this
    /// writing).  Service providers MAY add further values if new IM
    /// services are introduced and MAY specify more detailed
    /// canonicalization rules for each possible value.
    public var ims: [ScimMultiValuedAttribute]?
    
    /// A URI that is a uniform resource locator (as defined in
    /// Section 1.1.3 of [RFC3986]) that points to a resource location
    /// representing the user's image.  The resource MUST be a file (e.g.,
    /// a GIF, JPEG, or PNG image file) rather than a web page containing
    /// an image. Service providers MAY return the same image in
    /// different sizes, although it is recognized that no standard for
    /// describing images of various sizes currently exists. Note that
    /// this attribute SHOULD NOT be used to send down arbitrary photos
    /// taken by this user; instead, profile photos of the user that are
    /// suitable for display when describing the user should be sent.
    /// Instead of the standard canonical values for type, this attribute
    /// defines the following canonical values to represent popular photo
    /// sizes: "photo" and "thumbnail".
    public var photos: [ScimMultiValuedAttribute]?
    
    public var addresses: [ScimAddress]?
    
    /// A list of groups to which the user belongs, either through direct
    /// membership, through nested groups, or dynamically calculated.  The
    /// values are meant to enable expression of common group-based or
    /// role-based access control models, although no explicit
    /// authorization model is defined.  It is intended that the semantics
    /// of group membership and any behavior or authorization granted as a
    /// result of membership are defined by the service provider.  The
    /// canonical types "direct" and "indirect" are defined to describe
    /// how the group membership was derived.  Direct group membership
    /// indicates that the user is directly associated with the group and
    /// SHOULD indicate that clients may modify membership through the
    /// "Group" resource.  Indirect membership indicates that user
    /// membership is transitive or dynamic and implies that clients
    /// cannot modify indirect group membership through the "Group"
    /// resource but MAY modify direct group membership through the
    /// "Group" resource, which may influence indirect memberships.  If
    /// the SCIM service provider exposes a "Group" resource, the "value"
    /// sub-attribute MUST be the "id", and the "$ref" sub-attribute must
    /// be the URI of the corresponding "Group" resources to which the
    /// user belongs.  Since this attribute has a mutability of
    /// "readOnly", group membership changes MUST be applied via the
    /// "Group" Resource (Section 4.2). This attribute has a mutability
    /// of "readOnly".
    public var groups: [ScimMultiValuedAttribute]?
    
    /// A list of entitlements for the user that represent a thing the
    /// user has.  An entitlement may be an additional right to a thing,
    /// object, or service.  No vocabulary or syntax is specified; service
    /// providers and clients are expected to encode sufficient
    /// information in the value so as to accurately and without ambiguity
    /// determine what the user has access to.  This value has no
    /// canonical types, although a type may be useful as a means to scope
    /// entitlements.
    public var entitlements: AnyCodable? = []
    
    /// A list of roles for the user that collectively represent who the
    /// user is, e.g., "Student", "Faculty".  No vocabulary or syntax is
    /// specified, although it is expected that a role value is a String
    /// or label representing a collection of entitlements.  This value
    /// has no canonical types.
    public var roles: [String]?
    
    /// A list of certificates associated with the resource (e.g., a
    /// User). Each value contains exactly one DER- encoded X.509
    /// certificate(see Section 4 of [RFC5280]), which MUST be base64
    /// encoded per Section 4 of [RFC4648].A single value MUST NOT
    /// contain multiple certificates and so does not contain the encoding
    /// "SEQUENCE OF Certificate" in any guise.
    public var x509Certificates: [String]?
    
}

/// The components of the SCIM user's name.
/// Service providers MAY return
/// just the full name as a single string in the formatted
/// sub-attribute, or they MAY return just the individual component
/// attributes using the other sub-attributes, or they MAY return
/// both. If both variants are returned, they SHOULD be describing
/// the same name, with the formatted name indicating how the
/// component attributes should be combined.
public class ScimUserNames: Codable {
    
    /// The full name, including all middle names, titles, and
    /// suffixes as appropriate, formatted for display (e.g.,
    /// "Ms. Barbara Jane Jensen, III").
    public var formatted: String?
    
    /// The family name of the User, or last name in most
    /// Western languages (e.g., "Jensen" given the full name
    /// "Ms. Barbara Jane Jensen, III").
    public var familyName: String?
    
    /// The given name of the User, or first name in most
    /// Western languages (e.g., "Barbara" given the full name
    /// "Ms. Barbara Jane Jensen, III").
    public var givenName: String?
    
    /// The middle name(s) of the User (e.g., "Jane" given the
    /// full name "Ms. Barbara Jane Jensen, III").
    public var middleName: String?
    
    /// The honorific prefix(es) of the User, or title in
    /// most Western languages (e.g., "Ms." given the full name
    /// Ms. Barbara Jane Jensen, III").
    public var honorificPrefix: String?
    
    /// The honorific suffix(es) of the User, or suffix
    /// in most Western languages (e.g., "III" given the full name
    /// "Ms. Barbara Jane Jensen, III").
    public var honorificSuffix: String?
    
    public init(formatted: String? = nil,
                familyName: String? = nil,
                givenName: String? = nil,
                middleName: String? = nil,
                honorificPrefix: String? = nil,
                honorificSuffix: String? = nil) {
        self.formatted = formatted
        self.familyName = familyName
        self.givenName = givenName
        self.middleName = middleName
        self.honorificPrefix = honorificPrefix
        self.honorificSuffix = honorificSuffix
    }
    
}

public class ScimMultiValuedAttribute: Codable {
    
    // MARK: Attributes.
    
    /// A label indicating the attribute's function, e.g., "work" or
    /// "home".
    public var type: String
    
    /// The attribute's significant value, e.g., email address, phone
    /// number.
    public var value: String
    
    /// A Boolean value indicating the 'primary' or preferred attribute
    /// value for this attribute, e.g., the preferred mailing address or
    /// the primary email address. The primary attribute value "true"
    /// MUST appear no more than once. If not specified, the value of
    /// "primary" SHALL be assumed to be "false".
    public var primary: Bool?
    
    /// A human-readable name, primarily used for display purposes and
    /// having a mutability of "immutable".
    public var display: String?
    
    // MARK: Initializers.
    
    public init(type: String, value: String, primary: Bool? = nil, display: String? = nil) {
        self.type = type
        self.value = value
        self.primary = primary
        self.display = display
    }
    
    // MARK: - Codable methods.
    
    enum ScimMultiValuedAttributeKeys: String, CodingKey {
        case type
        case value
        case primary
        case display
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ScimMultiValuedAttributeKeys.self)
        self.type = try container.decode(String.self, forKey: .type)
        self.value = try container.decode(String.self, forKey: .value)
        self.primary = try container.decodeIfPresent(Bool.self, forKey: .primary)
        self.display = try container.decodeIfPresent(String.self, forKey: .display)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ScimMultiValuedAttributeKeys.self)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(value, forKey: .value)
        try container.encodeIfPresent(primary, forKey: .primary)
        try container.encodeIfPresent(display, forKey: .display)
    }
    
}

public class ScimAddress: ScimMultiValuedAttribute {
    
    /// The full mailing address, formatted for display or use
    /// with a mailing label. This attribute MAY contain newlines.
    public var formatted: String?
    
    /// The full street address component, which may
    /// include house number, street name, P.O.box, and multi- line
    /// extended street address information. This attribute MAY
    /// contain newlines.
    public var streetAddress: String?
    
    /// The city or locality component.
    public var locality: String?
    
    /// The state or region component.
    public var region: String?
    
    /// The zip code or postal code component.
    public var postalCode: String?
    
    /// The country name component.When specified, the value
    /// MUST be in ISO 3166-1 "alpha-2" code format [ISO3166]; e.g.,
    /// the United States and Sweden are "US" and "SE", respectively.
    public var country: String?
    
    // MARK: - Codable methods.
    
    enum ScimAddressKeys: String, CodingKey {
        case formatted
        case streetAddress
        case locality
        case region
        case postalCode
        case country
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ScimAddressKeys.self)
        self.formatted = try container.decodeIfPresent(String.self, forKey: .formatted)
        self.streetAddress = try container.decodeIfPresent(String.self, forKey: .streetAddress)
        self.locality = try container.decodeIfPresent(String.self, forKey: .locality)
        self.region = try container.decodeIfPresent(String.self, forKey: .region)
        self.postalCode = try container.decodeIfPresent(String.self, forKey: .postalCode)
        self.country = try container.decodeIfPresent(String.self, forKey: .country)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: ScimAddressKeys.self)
        try container.encodeIfPresent(formatted, forKey: .formatted)
        try container.encodeIfPresent(streetAddress, forKey: .streetAddress)
        try container.encodeIfPresent(locality, forKey: .locality)
        try container.encodeIfPresent(region, forKey: .region)
        try container.encodeIfPresent(postalCode, forKey: .postalCode)
        try container.encodeIfPresent(country, forKey: .country)
    }
}
