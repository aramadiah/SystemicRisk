% [INPUT]
% ds = A structure representing the dataset.
% validation_type = A string representing the type of validation to perform (optional, default='').

function ds = validate_dataset(varargin)

    persistent validation_types;
    
    if (isempty(validation_types))
        validation_types = {
            'component' 'connectedness' 'cross-entropy' 'cross-quantilogram' ...
            'cross-sectional' 'default' 'liquidity' 'regime-switching' 'spillover'
        };
    end
    
    persistent ip;

    if (isempty(ip))
        ip = inputParser();
        ip.addRequired('ds',@(x)validateattributes(x,{'struct'},{'nonempty'}));
        ip.addOptional('validation_type','',@(x)any(validatestring(x,validation_types)));
    end

    ip.parse(varargin{:});

    ipr = ip.Results;
    ds = ipr.ds;
    validation_type = ipr.validation_type;
    
    nargoutchk(1,1);

    ds = validate_dataset_internal(ds,validation_type);

end

function ds = validate_dataset_internal(ds,validation_type)

    validate_field(ds,'TimeSeries',{'cellstr'},{'nonempty' 'size' [1 8]});

    validate_field(ds,'File',{'char'},{'nonempty' 'size' [1 NaN]});
    validate_field(ds,'Version',{'char'},{'nonempty' 'size' [1 NaN]});

    n = validate_field(ds,'N',{'double'},{'real' 'finite' 'integer' '>=' 3 'scalar'});
    t = validate_field(ds,'T',{'double'},{'real' 'finite' 'integer' '>=' 252 'scalar'});

    validate_field(ds,'DatesNum',{'double'},{'real' 'finite' 'integer' '>' 0 'nonempty' 'size' [t 1]});
    validate_field(ds,'DatesStr',{'cellstr'},{'nonempty' 'size' [t 1]});
    validate_field(ds,'MonthlyTicks',{'logical'},{'scalar'});

    validate_field(ds,'IndexName',{'char'},{'nonempty' 'size' [1 NaN]});
    validate_field(ds,'FirmNames',{'cellstr'},{'nonempty' 'size' [1 n]});
    
    validate_field(ds,'Index',{'double'},{'real' 'finite' 'nonempty' 'size' [t 1]});
    validate_field(ds,'Returns',{'double'},{'real' 'nanfinite' 'nonempty' 'size' [t n]});

    validate_field(ds,'Prices',{'double'},{'optional' 'real' 'nanfinite' 'nonnegative' 'nonempty' 'size' [t n]});
    validate_field(ds,'Volumes',{'double'},{'optional' 'real' 'nanfinite' 'nonnegative' 'nonempty' 'size' [t n]});
    validate_field(ds,'Capitalizations',{'double'},{'optional' 'real' 'nanfinite' 'nonnegative' 'nonempty' 'size' [t n]});

    validate_field(ds,'RiskFreeRate',{'double'},{'optional' 'real' 'finite' 'nonempty' 'size' [t 1]});
    validate_field(ds,'CDS',{'double'},{'optional' 'real' 'nanfinite' 'nonnegative' 'nonempty' 'size' [t n]});

    validate_field(ds,'Assets',{'double'},{'optional' 'real' 'nanfinite' 'nonnegative' 'nonempty' 'size' [t n]});
    validate_field(ds,'Equity',{'double'},{'optional' 'real' 'nanfinite' 'nonempty' 'size' [t n]});
    validate_field(ds,'Liabilities',{'double'},{'optional' 'real' 'nanfinite' 'nonnegative' 'nonempty' 'size' [t n]});
    validate_field(ds,'SeparateAccounts',{'double'},{'optional' 'real' 'nanfinite' 'nonnegative' 'nonempty' 'size' [t n]});

    state_variables = validate_field(ds,'StateVariables',{'double'},{'optional' 'real' 'finite' 'nonempty' 'size' [t NaN]});
    validate_field(ds,'StateVariablesNames',{'cellstr'},{'optional' 'nonempty' 'size' [1 size(state_variables,2)]});

    groups = validate_field(ds,'Groups',{'double'},{'real' 'finite' 'integer' '>=' 0 'scalar'});

    if (groups == 0)
        validate_field(ds,'GroupDelimiters',{'double'},{'size' [0 0]});
        validate_field(ds,'GroupNames',{'double'},{'size' [0 0]});
        validate_field(ds,'GroupShortNames',{'double'},{'size' [0 0]});
    else
        validate_field(ds,'GroupDelimiters',{'double'},{'real' 'finite' 'integer' 'positive' 'increasing' 'nonempty' 'size' [(groups - 1) 1]});
        validate_field(ds,'GroupNames',{'cellstr'},{'nonempty' 'size' [groups 1]});
        validate_field(ds,'GroupShortNames',{'cellstr'},{'nonempty' 'size' [groups 1]});
    end
    
    crises = validate_field(ds,'Crises',{'double'},{'real' 'finite' 'integer' '>=' 0 'scalar'});
    crises_type = validate_field(ds,'CrisesType',{'char'},{'nonempty' 'size' [1 1]});
    
    if (~strcmp(crises_type,'E') && ~strcmp(crises_type,'R'))
        error(['The dataset field ''crises_type'' is invalid.' newline() 'Expected value to be either ''E'' or ''R''.']);
    end
    
    if (crises == 0)
        validate_field(ds,'CrisesDummy',{'double'},{'size' [0 0]});
        validate_field(ds,'CrisisDates',{'double'},{'size' [0 0]});
        validate_field(ds,'CrisisDummies',{'double'},{'size' [0 0]});
        validate_field(ds,'CrisisNames',{'double'},{'size' [0 0]});
    else
        validate_field(ds,'CrisesDummy',{'double'},{'real' 'finite' 'integer' '>=' 0 '<=' 1 'nonempty' 'size' [t 1]});
        
        if (strcmp(crises_type,'E'))
            validate_field(ds,'CrisisDates',{'double'},{'real' 'finite' 'integer' '>' 0 'nonempty' 'size' [crises 1]});
            validate_field(ds,'CrisisDummies',{'double'},{'size' [0 0]});
        else
            validate_field(ds,'CrisisDates',{'double'},{'real' 'finite' 'integer' '>' 0 'nonempty' 'size' [crises 2]});
            validate_field(ds,'CrisisDummies',{'double'},{'real' 'finite' 'integer' '>=' 0 '<=' 1 'nonempty' 'size' [t crises]});
        end
        
        validate_field(ds,'CrisisNames',{'cellstr'},{'nonempty' 'size' [crises 1]});
    end

    validate_field(ds,'Defaults',{'double'},{'real' 'nonempty' 'offset' 'size' [1 n]});
    validate_field(ds,'Insolvencies',{'double'},{'real' 'nonempty' 'offset' 'size' [1 n]});

    validate_field(ds,'SupportsComponent',{'logical'},{'scalar'});
    validate_field(ds,'SupportsConnectedness',{'logical'},{'scalar'});
	validate_field(ds,'SupportsCrossEntropy',{'logical'},{'scalar'});
    validate_field(ds,'SupportsCrossSectional',{'logical'},{'scalar'});
    validate_field(ds,'SupportsDefault',{'logical'},{'scalar'});
    validate_field(ds,'SupportsLiquidity',{'logical'},{'scalar'});
    validate_field(ds,'SupportsRegimeSwitching',{'logical'},{'scalar'});
    validate_field(ds,'SupportsSpillover',{'logical'},{'scalar'});
    validate_field(ds,'SupportsComparison',{'logical'},{'scalar'});
    
    if (~isempty(validation_type))
		measures = [upper(validation_type(1)) validation_type(2:end)];
		measures_underscore = strfind(measures,'-');

		if (~isempty(measures_underscore))
			measures(measures_underscore) = [];
			measures(measures_underscore) = upper(measures(measures_underscore));
		end

		supports = ['Supports' measures];

		if (~ds.(supports))
			error(['The dataset cannot be used for calculating ''' validation_type ''' measures.']);
		end
    end
    
end

function value = validate_field(ds,field_name,field_type,field_validator)

    if (~isfield(ds,field_name))
        error(['The dataset does not contain the field ''' field_name '''.']);
    end

    value = ds.(field_name);
    value_iscellstr = (numel(field_type) == 1) && strcmp(field_type{1},'cellstr');
    value_isfinite = any(strcmp(field_validator,'nanfinite'));
    value_isoffset = any(strcmp(field_validator,'offset'));
    value_isoptional = strcmp(field_validator{1},'optional');

    if (value_isoptional)
        empty = false;

        try
            validateattributes(value,{'double'},{'size' [0 0]});
            empty = true;
        catch
        end
        
        if (empty)
            return;
        end
        
        field_validator = field_validator(2:end);
    end
    
    if (value_iscellstr)
        if (~iscellstr(value) || any(cellfun(@length,value) == 0) || any(cellfun(@(x)size(x,1),value) ~= 1)) %#ok<ISCLSTR>
            error(['The dataset field ''' field_name ''' is invalid.' newline() 'Expected value to be a cell array of non-empty character vectors.']);
        end

        field_type{1} = 'cell';
    else
        if (value_isfinite)
            index = strcmp(field_validator,'nanfinite');
            field_validator(index) = [];
        end
        
        if (value_isoffset)
            index = strcmp(field_validator,'offset');
            field_validator(index) = [];
        end
    end

    try
        validateattributes(value,field_type,field_validator);
    catch e
        error(['The dataset field ''' field_name ''' is invalid.' newline() strrep(e.message,'Expected input','Expected value')]);
    end
    
    if (value_isfinite)
        value_check = value;
        value_check(isnan(value_check)) = 0;

        try
            validateattributes(value_check,field_type,{'finite'});
        catch
            error(['The dataset field ''' field_name ''' is invalid.' newline() 'Expected value to be finite.']);
        end
    end
    
    if (value_isoffset)
        value_check = value;
        value_check(isnan(value_check)) = 2;

        try
            validateattributes(value_check,field_type,{'>',1});
        catch
            error(['The dataset field ''' field_name ''' is invalid.' newline() 'Expected value to contain all the finite values > 1.']);
        end
    end

end
